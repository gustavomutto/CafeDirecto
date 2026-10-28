import { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from './Icon';

/** Panel de control de la demo (fuera del celular). En móvil se abre con un botón flotante. */
export default function DemoPanel() {
  const { state, role, actions, meFarm, meBuyer, pendingCount } = useApp();
  const navigate = useNavigate();
  const location = useLocation();
  const [openMobile, setOpenMobile] = useState(false);

  // Al cambiar de rol se queda en la misma pantalla si ambas personas participan en ella
  const switchRole = (r) => {
    if (r === role) return;
    actions.setRole(r);
    const path = location.pathname;
    const chat = path.match(/^\/chat\/(.+)$/);
    const order = path.match(/^\/orders\/(.+)$/);
    const sharedChat = chat && state.conversations.some((c) => c.id === chat[1] && c.farmId === state.me.farmer && c.buyerId === state.me.buyer);
    const sharedOrder = order && state.agreements.some((a) => a.id === order[1] && a.farmId === state.me.farmer && a.buyerId === state.me.buyer);
    const neutral = /^\/(lot|farm|buyer|learn|fees)/.test(path);
    if (!(sharedChat || sharedOrder || neutral)) navigate('/home');
  };

  const onReset = () => {
    if (window.confirm('¿Reiniciar todos los datos de la demo?')) {
      actions.reset();
      navigate('/welcome');
    }
  };

  const panel = (
    <aside className={`demo-panel ${openMobile ? 'open' : ''}`}>
      <div className="dp-head">
        <div className="dp-logo">☕</div>
        <div>
          <b>CaféDirecto</b>
          <small>Panel de demo · no es parte de la app</small>
        </div>
        <button className="dp-close" onClick={() => setOpenMobile(false)} aria-label="Cerrar panel">
          <Icon name="x" />
        </button>
      </div>

      <section>
        <label>Ver la app como</label>
        <div className="dp-roles">
          <button className={role === 'farmer' ? 'active' : ''} onClick={() => switchRole('farmer')}>
            <span>👩🏽‍🌾</span>
            <b>Caficultor</b>
            <small>{meFarm.producer} · Huila · ES</small>
          </button>
          <button className={role === 'buyer' ? 'active' : ''} onClick={() => switchRole('buyer')}>
            <span>☕</span>
            <b>Buyer</b>
            <small>{meBuyer.contact} · Berlin · EN</small>
          </button>
        </div>
      </section>

      <section>
        <label>Conectividad</label>
        <button className={`dp-toggle ${state.offline ? 'on' : ''}`} onClick={actions.toggleOffline}>
          <span className="dp-switch"><i /></span>
          <span>
            <b>{state.offline ? 'Sin conexión (activo)' : 'Simular sin conexión'}</b>
            <small>
              {state.syncing
                ? 'Sincronizando…'
                : state.offline
                  ? `${pendingCount} elemento(s) en cola`
                  : 'Los envíos quedarán pendientes'}
            </small>
          </span>
        </button>
      </section>

      <section className="dp-actions">
        <label>Datos</label>
        <button onClick={() => { actions.replayOnboarding(); navigate('/welcome'); }}>
          <Icon name="sparkles" size={18} /> Ver onboarding
        </button>
        <button onClick={onReset} className="danger">
          <Icon name="sync" size={18} /> Reiniciar datos
        </button>
      </section>

      <section className="dp-tip">
        <b>Tip para presentar</b>
        <p>Abre el chat Berlín ↔ Huila y cambia de rol: verás la misma conversación en inglés y en español.</p>
      </section>
    </aside>
  );

  return (
    <>
      {panel}
      <button className="dp-fab" onClick={() => setOpenMobile(true)} aria-label="Abrir panel de demo">
        <Icon name="sparkles" size={18} /> Demo
      </button>
      {openMobile && <div className="dp-backdrop" onClick={() => setOpenMobile(false)} />}
    </>
  );
}
