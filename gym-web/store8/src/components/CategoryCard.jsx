import { Link } from 'react-router-dom'
import { categoryIcon } from '../utils/categoryIcons'

export default function CategoryCard({ category }) {
  return (
    <Link to={`/category/${category.id}`} className="card category-card">
      <div className="icon-wrap">{categoryIcon(category.icon)}</div>
      <h3>{category.name}</h3>
      <p>{category.tagline}</p>
    </Link>
  )
}
