import { useApp } from '../context/AppContext';
import { STATUS_STEPS } from '../data/catalog';
import { fmtDate } from '../utils';
import Icon from './Icon';

/** Línea de estado Cotizado → Confirmado → Enviado → Entregado */
export default function StatusTimeline({ status, history = [], vertical = false }) {
  const { pick, lang } = useApp();
  return (
    <ol className={`timeline ${vertical ? 'vertical' : ''}`}>
      {STATUS_STEPS.map((s, i) => {
        const state = i < status ? 'done' : i === status ? 'current' : 'todo';
        return (
          <li key={s.key} className={state}>
            <span className="tl-dot">
              <Icon name={i <= status ? (i === status ? s.icon : 'check') : s.icon} size={vertical ? 18 : 14} stroke={2.4} />
            </span>
            <span className="tl-text">
              <b>{pick(s)}</b>
              {vertical && history[i] && <small>{fmtDate(history[i], lang)}</small>}
            </span>
          </li>
        );
      })}
    </ol>
  );
}
