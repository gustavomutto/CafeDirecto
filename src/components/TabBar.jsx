import { NavLink } from 'react-router-dom';
import Icon from './Icon';
import { useApp } from '../context/AppContext';

export default function TabBar() {
  const { role, tr, unreadTotal } = useApp();
  const tabs = [
    { to: '/home', icon: role === 'farmer' ? 'home' : 'compass', label: tr('Inicio', 'Explore') },
    { to: '/chats', icon: 'chat', label: tr('Mensajes', 'Messages'), badge: unreadTotal },
    { to: '/orders', icon: 'receipt', label: tr('Acuerdos', 'Orders') },
    { to: '/learn', icon: 'book', label: tr('Aprende', 'Learn') },
    { to: '/me', icon: 'user', label: tr('Mi finca', 'Profile') },
  ];
  return (
    <nav className="tabbar">
      {tabs.map((t) => (
        <NavLink key={t.to} to={t.to} className={({ isActive }) => `tab ${isActive ? 'active' : ''}`}>
          <span className="tab-icon">
            <Icon name={t.icon} size={role === 'farmer' ? 26 : 23} />
            {t.badge > 0 && <span className="badge">{t.badge > 9 ? '9+' : t.badge}</span>}
          </span>
          <span className="tab-label">{t.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
