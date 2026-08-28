// Client-side Firebase Auth init for the OPTIONAL customer login/registration feature.
// This is the same Firebase project the admin app already uses (see
// gym-app/store8/lib/firebase_options.dart -> DefaultFirebaseOptions.web) — nothing below is a
// secret that needs hiding; Firebase client config is meant to be embedded in apps like this
// one. Auth is all this file is used for: the storefront never talks to Firestore/Storage
// directly (see gym-backend/DATA_MODEL.md — "API is the only way in"), it only asks Firebase to
// sign a user in/up and then sends the resulting ID token to our own backend as a bearer token.
import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'

const firebaseConfig = {
  apiKey: 'AIzaSyDJxvtubYvv0bjdnPSL2NAp4iHl8NWSyWI',
  authDomain: 'store-8-tech.firebaseapp.com',
  projectId: 'store-8-tech',
  storageBucket: 'store-8-tech.firebasestorage.app',
  messagingSenderId: '326403588670',
  appId: '1:326403588670:web:640f151c0420f47b78876f',
}

export const firebaseApp = initializeApp(firebaseConfig)
export const auth = getAuth(firebaseApp)
