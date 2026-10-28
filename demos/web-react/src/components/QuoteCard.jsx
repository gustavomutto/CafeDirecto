import { useApp } from '../context/AppContext';
import { INCOTERMS, PROCESSES } from '../data/catalog';
import { fmtNum, fmtUSD, quoteTotal, KG_PER_SACK } from '../utils';
import Icon from './Icon';

/**
 * Cotización en el chat.
 * - status 'open': quien NO hizo la última oferta puede Aceptar o Contraofertar.
 * - status 'accepted': la otra parte debe Confirmar → se registra el acuerdo.
 * - status 'agreed': muestra que el acuerdo quedó registrado.
 * - status 'superseded': versión anterior, se muestra compacta.
 */
export default function QuoteCard({ msg, onAccept, onCounter, onConfirm }) {
  const { state, role, tr, pick, lang } = useApp();
  const q = msg.quote;
  const lot = state.lots.find((l) => l.id === q.lotId);
  const total = quoteTotal(q.priceLb, q.sacks);
  const who = (r) => (r === 'farmer' ? tr('Caficultor', 'Farmer') : tr('Comprador', 'Buyer'));
  const isCounter = q.history.length > 1;

  if (q.status === 'superseded') {
    return (
      <div className="quote-card superseded">
        <Icon name="tag" size={16} />
        <span>
          {isCounter ? tr('Contraoferta', 'Counter-offer') : tr('Cotización', 'Quote')}: <s>{fmtUSD(q.priceLb, lang)}/lb · {q.sacks} {tr('sacos', 'bags')}</s>
        </span>
        <small>{tr('reemplazada', 'replaced')}</small>
      </div>
    );
  }

  const myTurn = q.status === 'open' && q.lastBy !== role;
  const mustConfirm = q.status === 'accepted' && q.acceptedBy !== role;

  return (
    <div className={`quote-card status-${q.status}`}>
      <div className="qc-head">
        <span className="qc-icon"><Icon name="tag" size={18} /></span>
        <div>
          <b>{isCounter ? tr('Contraoferta', 'Counter-offer') : tr('Cotización', 'Price quote')}</b>
          <small>{tr('de', 'from')} {who(q.lastBy)}</small>
        </div>
        <span className={`qc-status ${q.status}`}>
          {q.status === 'open' && tr('Abierta', 'Open')}
          {q.status === 'accepted' && tr('Aceptada', 'Accepted')}
          {q.status === 'agreed' && tr('Cerrada', 'Closed')}
        </span>
      </div>

      <div className="qc-price">
        <b>{fmtUSD(q.priceLb, lang)}</b>
        <span>/ lb</span>
      </div>

      <dl className="qc-terms">
        <div><dt>{tr('Lote', 'Lot')}</dt><dd>{lot?.name} · {lot?.variety} {lot && pick(PROCESSES[lot.process])}</dd></div>
        <div><dt>{tr('Cantidad', 'Quantity')}</dt><dd>{q.sacks} × {KG_PER_SACK} kg ({fmtNum(q.sacks * KG_PER_SACK, lang)} kg)</dd></div>
        <div><dt>{tr('Condición', 'Terms')}</dt><dd>{pick(INCOTERMS[q.incoterm]) || q.incoterm}</dd></div>
        <div><dt>{tr('Total', 'Total')}</dt><dd><b>{fmtUSD(total, lang, 0)}</b></dd></div>
      </dl>

      {q.history.length > 1 && (
        <div className="qc-history">
          {q.history.map((h, i) => (
            <span key={i} className={i === q.history.length - 1 ? 'last' : ''}>
              {who(h.by)}: {fmtUSD(h.priceLb, lang)}
            </span>
          ))}
        </div>
      )}

      {myTurn && (
        <div className="qc-actions">
          <button className="btn btn-outline" onClick={() => onCounter(msg)}>
            {tr('Contraofertar', 'Counter')}
          </button>
          <button className="btn btn-primary" onClick={() => onAccept(msg)}>
            <Icon name="check" size={18} /> {tr('Aceptar', 'Accept')}
          </button>
        </div>
      )}
      {q.status === 'open' && !myTurn && (
        <p className="qc-wait"><Icon name="clock" size={14} /> {tr('Esperando respuesta…', 'Waiting for a reply…')}</p>
      )}
      {mustConfirm && (
        <div className="qc-actions">
          <button className="btn btn-primary btn-block" onClick={() => onConfirm(msg)}>
            <Icon name="handshake" size={18} /> {tr('Confirmar acuerdo', 'Confirm agreement')}
          </button>
        </div>
      )}
      {q.status === 'accepted' && !mustConfirm && (
        <p className="qc-wait"><Icon name="clock" size={14} /> {tr('Aceptaste · esperando confirmación de la otra parte', 'You accepted · waiting for the other party to confirm')}</p>
      )}
      {q.status === 'agreed' && (
        <p className="qc-done"><Icon name="checks" size={16} /> {tr('Ambas partes confirmaron', 'Both parties confirmed')}</p>
      )}
    </div>
  );
}
