import { useEffect, useState } from 'react';
import Icon from './Icon';
import { useApp } from '../context/AppContext';

function StatusBar() {
  const { state } = useApp();
  const [now, setNow] = useState(new Date());
  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 20000);
    return () => clearInterval(t);
  }, []);
  const time = now.toLocaleTimeString('es-CO', { hour: '2-digit', minute: '2-digit', hour12: false });
  return (
    <div className="statusbar">
      <span className="sb-time">{time}</span>
      <span className="sb-notch" />
      <span className="sb-icons">
        <span className={`sb-signal ${state.offline ? 'off' : ''}`}>
          <i /><i /><i /><i />
        </span>
        {state.offline ? <Icon name="wifiOff" size={15} stroke={2.2} /> : <span className="sb-net">4G</span>}
        <span className="sb-battery"><i /></span>
      </span>
    </div>
  );
}

function NetworkBanner() {
  const { state, tr, pendingCount } = useApp();
  if (state.syncing) {
    return (
      <div className="net-banner syncing">
        <Icon name="sync" size={18} className="spin" />
        <span>{tr('Conexión recuperada · sincronizando…', 'Back online · syncing…')}</span>
      </div>
    );
  }
  if (!state.offline) return null;
  return (
    <div className="net-banner offline">
      <Icon name="wifiOff" size={18} />
      <span>
        <b>{tr('Sin señal', 'No signal')}</b>{' '}
        {pendingCount > 0
          ? tr(`· ${pendingCount} pendiente(s) de envío`, `· ${pendingCount} pending`)
          : tr('· puedes seguir usando la app', '· you can keep using the app')}
      </span>
    </div>
  );
}

function Toast() {
  const { toast } = useApp();
  if (!toast) return null;
  return (
    <div className="toast" key={toast.id}>
      <span className="toast-icon">{toast.icon}</span>
      <span>{toast.text}</span>
    </div>
  );
}

export default function PhoneFrame({ children, tabBar }) {
  const { role } = useApp();
  return (
    <div className={`phone role-${role}`}>
      <div className="phone-screen">
        <StatusBar />
        <NetworkBanner />
        <Toast />
        <main className="viewport">{children}</main>
        {tabBar}
        <div className="home-indicator" />
      </div>
    </div>
  );
}
