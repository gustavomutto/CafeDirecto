import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import LotCard from '../components/LotCard';
import { Avatar, EmptyState, Img, ScoreBadge, Segmented, Stars, TopBar } from '../components/ui';
import { NOTES, PROCESSES } from '../data/catalog';
import { farmRating, fmtNum } from '../utils';

/** Perfil de finca con versión ES/EN — RF-02, RF-04 */
export default function FarmProfile({ farmId, own = false, extra = null }) {
  const params = useParams();
  const navigate = useNavigate();
  const { state, role, lang, actions } = useApp();
  const [cLang, setCLang] = useState(lang);
  const farm = state.farms.find((f) => f.id === (farmId || params.id));
  if (!farm) return <div className="screen"><TopBar /><EmptyState title="—" /></div>;

  // Toda la ficha (etiquetas y contenido) cambia con el botón ES/EN
  const T = (es, en) => (cLang === 'es' ? es : en);
  const P = (obj) => obj?.[cLang];
  const rating = farmRating(farm, state.agreements);
  const lots = state.lots.filter((l) => l.farmId === farm.id);
  const agreementReviews = state.agreements
    .filter((a) => a.farmId === farm.id && a.ratings?.byBuyer)
    .map((a) => {
      const b = state.buyers.find((x) => x.id === a.buyerId);
      return { by: `${b.company} · ${b.cityEn}`, stars: a.ratings.byBuyer.stars, text: a.ratings.byBuyer.comment, verified: true };
    });
  const reviews = [...agreementReviews, ...farm.reviews];

  const message = () => {
    const cid = actions.startConversation(farm.id, state.me.buyer, { lotId: lots[0]?.id });
    navigate(`/chat/${cid}`);
  };

  return (
    <div className="screen farm-profile">
      <div className="screen-body no-pad">
        <div className="cover">
          <Img src={farm.cover} alt={farm.name} />
          <div className="hero-shade" />
          {!own && <TopBar transparent />}
        </div>

        <div className="pad profile-main">
          <div className="profile-id">
            <Avatar src={farm.producerPhoto} name={farm.producer} size={84} className="ring" />
            <ScoreBadge sca={farm.sca} />
          </div>
          <h1>{farm.name}</h1>
          <p className="muted">{farm.producer} · {farm.municipality}, {farm.region}</p>
          <Stars value={rating.avg} size={16} showValue count={rating.count} />

          <div className="lang-toggle">
            <span>{T('Ver perfil en', 'View profile in')}</span>
            <Segmented small value={cLang} onChange={setCLang} options={[{ value: 'es', label: 'ES' }, { value: 'en', label: 'EN' }]} />
          </div>
          {own && (
            <p className="own-banner">
              <Icon name="eye" size={16} /> {cLang === 'en' ? 'Así ven tu finca los compradores (en inglés)' : 'Así se ve tu finca en español'}
            </p>
          )}

          <blockquote className="farm-quote">{P(farm.quote)}</blockquote>

          <h3 className="section-title">{T('Nuestra historia', 'Our story')}</h3>
          <p className="story">{P(farm.story)}</p>

          <div className="gallery">
            {farm.gallery.map((g) => <Img key={g} src={g} alt="" />)}
          </div>

          <div className="spec-grid">
            <div className="spec"><Icon name="mountain" size={18} /><small>{T('Altitud', 'Altitude')}</small><b>{fmtNum(farm.altitude, cLang)} m</b></div>
            <div className="spec"><Icon name="leaf" size={18} /><small>{T('Tamaño', 'Size')}</small><b>{farm.hectares} ha</b></div>
            <div className="spec"><Icon name="clock" size={18} /><small>{T('Cultivando desde', 'Growing since')}</small><b>{farm.since}</b></div>
            <div className="spec"><Icon name="star" size={18} /><small>{T('Puntaje SCA', 'SCA score')}</small><b>{farm.sca}</b></div>
            <div className="spec wide"><Icon name="bean" size={18} /><small>{T('Variedades', 'Varieties')}</small><b>{farm.varieties.join(', ')}</b></div>
            <div className="spec wide"><Icon name="sync" size={18} /><small>{T('Proceso poscosecha', 'Post-harvest process')}</small><b>{farm.processes.map((p) => `${PROCESSES[p].icon} ${PROCESSES[p][cLang]}`).join(' · ')}</b></div>
          </div>

          <h3 className="section-title">{T('Notas de catación', 'Cupping notes')}</h3>
          <div className="chip-wrap">
            {farm.notes.map((n) => <span key={n} className="note-chip">{NOTES[n][cLang]}</span>)}
          </div>

          <h3 className="section-title">{T('Certificaciones (solo lectura)', 'Certifications (view only)')}</h3>
          <div className="cert-list">
            {farm.certifications.map((c) => (
              <div key={c.name} className="cert">
                <Icon name="shield" size={20} />
                <span><b>{c.name}</b><small>{c.issuer}</small></span>
                <Icon name="lock" size={16} className="muted" />
              </div>
            ))}
          </div>

          <h3 className="section-title">{T('Lotes disponibles', 'Available lots')}</h3>
          <div className="lot-rows">
            {lots.map((l) => <LotCard key={l.id} lot={l} compact />)}
          </div>

          <h3 className="section-title">{T('Reputación', 'Reputation')} · {rating.avg.toFixed(1)} ★</h3>
          {reviews.length === 0 && <p className="muted">{T(`${rating.count} calificaciones anteriores`, `${rating.count} previous ratings`)}</p>}
          <div className="reviews">
            {reviews.map((r, i) => (
              <div key={i} className="review">
                <div className="review-top">
                  <b>{r.by}</b>
                  <Stars value={r.stars} size={12} />
                </div>
                {r.text && <p>{P(r.text)}</p>}
                {r.verified && <small className="verified-deal"><Icon name="check" size={12} /> {T('Acuerdo verificado en CaféDirecto', 'Verified CaféDirecto deal')}</small>}
              </div>
            ))}
          </div>
          {extra}
        </div>
      </div>

      {role === 'buyer' && !own && (
        <div className="screen-footer">
          <button className="btn btn-primary btn-block btn-lg" onClick={message}>
            <Icon name="chat" size={20} /> Message {farm.producer.split(' ')[0]}
          </button>
        </div>
      )}
    </div>
  );
}
