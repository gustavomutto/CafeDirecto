import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import BuyerProfile from './BuyerProfile';
import FarmProfile from './FarmProfile';

/** Pestaña "Mi finca" / "Profile": el perfil propio + accesos útiles */
export default function MyProfile() {
  const { role, state, tr } = useApp();
  const links = (
    <div className="my-links">
      <Link to="/fees" className="my-link">
        <Icon name="dollar" /> <span>{tr('Comisiones y condiciones', 'Fees & terms')}</span> <Icon name="chevron" size={18} />
      </Link>
      {role === 'farmer' && (
        <Link to="/publish" className="my-link">
          <Icon name="plus" /> <span>Publicar un lote nuevo</span> <Icon name="chevron" size={18} />
        </Link>
      )}
    </div>
  );
  return role === 'farmer'
    ? <FarmProfile farmId={state.me.farmer} own extra={links} />
    : <BuyerProfile buyerId={state.me.buyer} own extra={links} />;
}
