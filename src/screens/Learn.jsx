import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { LEARN } from '../data/learn';

/** Sección Aprende — RF-25 a RF-27 */
export default function Learn() {
  const { tr, pick } = useApp();
  const sections = [
    { key: 'post', title: tr('Buenas prácticas de poscosecha', 'Post-harvest best practices') },
    { key: 'export', title: tr('Exportar y vender', 'Exporting & selling') },
  ];
  return (
    <div className="screen">
      <div className="screen-body">
        <header className="page-head">
          <h1>{tr('Aprende', 'Learn')}</h1>
          <p className="muted">{tr('Lecturas de 1 minuto', '1-minute reads')}</p>
        </header>

        <Link to="/fees" className="fees-banner">
          <span className="fees-emoji">💰</span>
          <span>
            <b>{tr('Comisiones y condiciones', 'Fees & terms')}</b>
            <small>{tr('Claro y sin letra pequeña', 'Clear, no fine print')}</small>
          </span>
          <Icon name="chevron" />
        </Link>

        {sections.map((s) => (
          <section key={s.key}>
            <h3 className="section-title">{s.title}</h3>
            <div className="learn-grid">
              {LEARN.filter((l) => l.section === s.key).map((l) => (
                <Link key={l.id} to={`/learn/${l.id}`} className="learn-card" style={{ '--tint': l.color }}>
                  <span className="learn-icon">{l.icon}</span>
                  <b>{pick(l.title)}</b>
                  <small>{pick(l.summary)}</small>
                  <span className="learn-min"><Icon name="clock" size={12} /> {l.minutes} min</span>
                </Link>
              ))}
            </div>
          </section>
        ))}
      </div>
    </div>
  );
}
