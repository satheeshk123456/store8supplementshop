import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.firebase import init_firebase
from app.rate_limit import limiter
from app.routers import admin_meta, brands, categories, device_tokens, items, orders, products, search, uploads

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger("store8")

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Runs once per cold start of whatever's hosting this (a normal server process, or the
    # first request to a fresh Vercel Function instance — Vercel keeps the instance warm for
    # subsequent requests, so this doesn't re-run on every call).
    init_firebase()
    logger.info("%s started (env=%s)", settings.app_name, settings.env)
    yield


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,  # hide Swagger UI in prod
    redoc_url=None,
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), camera=(), microphone=()"
    if settings.is_production:
        response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains"
    return response


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # Return a short, non-technical message instead of a raw Pydantic error dump.
    first = exc.errors()[0] if exc.errors() else {}
    field = ".".join(str(p) for p in first.get("loc", [])[1:])
    message = first.get("msg", "Invalid request")
    return JSONResponse(status_code=422, content={"detail": f"{field}: {message}" if field else message})


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    if settings.is_production:
        return JSONResponse(status_code=500, content={"detail": "Something went wrong. Please try again."})
    raise exc


@app.get("/health")
def health():
    return {"status": "ok"}


app.include_router(categories.router)
app.include_router(brands.router)
app.include_router(products.router)
app.include_router(items.router)
app.include_router(search.router)
app.include_router(orders.router)
app.include_router(device_tokens.router)
app.include_router(uploads.router)
app.include_router(admin_meta.router)
