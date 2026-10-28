import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Icon from '../components/Icon';
import { Avatar, EmptyState, Img, Segmented, Stars, TopBar, Verified } from '../components/ui';
import { buyerRating } from '../utils';

/** Perfil del comprador con insignia Verificado — RF-03, RF-05 */
export default function BuyerProfile({ buyerId, own = false, extra = null }) {
  const params = useParams();
  const { state, lang } = useApp();
  const [cLang, setCLang] = useState(lang);
  const buyer = state.buyers.find((b) => b.id === (buyerId || params.id));
  if (!buyer) return <div className="screen"><TopBar /><EmptyState title="—" /></div>;

  const T = (es, en) => (cLang === 'es' ? es : en);
  const P = (obj) => obj?.[cLang];
  const rating = buyerRating(buyer, state.agreements);
  const deals = state.agreements.filter((a) => a.buyerId === buyer.id);
  const agreementReviews = deals
    .filter((a) => a.ratings?.byFarmer)
    .map((a) => {
      const f = state.farms.find((x) => x.id === a.farmId);
      return { by: `${f.name} · ${f.region}`, stars: a.ratings.byFarmer.stars, text: a.ratings.byFarmer.comment, verified: true };
    });
  const reviews = [...agreementReviews, ...buyer.reviews];

  return (
    <div className="screen buyer-profile">
      <div className="screen-body no-pad">
        <div className="cover">
          <Img src={buyer.cover} alt={buyer.company} />
          <div className="hero-shade" />
          {!own && <TopBar transparent />}
        </div>
        <div className="pad profile-main">
          <div className="profile-id">
            <Avatar src={buyer.contactPhoto} name={buyer.contact} size={84} className="ring" />
            <span className="flag-big">{buyer.flag}</span>
          </div>
          <h1>{buyer.company}</h1>
          <p className="muted">{buyer.contact} · {P(buyer.contactRole)}</p>
          <div className="row gap wrap">
            {buyer.verified && <Verified label={T('Verificado', 'Verified')} />}
            <Stars value={rating.avg} size={15} showValue count={rating.count} />
          </div>

          <div className="lang-toggle">
            <span>{T('Ver perfil en', 'View profile in')}</span>
            <Segmented small value={cLang} onChange={setCLang} options={[{ value: 'es', label: 'ES' }, { value: 'en', label: 'EN' }]} />
          </div>

          <div className="spec-grid">
            <div className="spec"><Icon name="pin" size={18} /><small>{T('Ciudad', 'City')}</small><b>{cLang === 'es' ? buyer.city : buyer.cityEn}, {P(buyer.country)}</b></div>
            <div className="spec"><Icon name="user" size={18} /><small>{T('Tipo de comprador', 'Buyer type')}</small><b>{P(buyer.type)}</b></div>
            <div className="spec"><Icon name="receipt" size={18} /><small>{T('Volumen de compra', 'Purchase volume')}</small><b>{P(buyer.volume)}</b></div>
            <div className="spec"><Icon name="clock" size={18} /><small>{T('Comprando desde', 'Buying since')}</small><b>{buyer.since}</b></div>
          </div>

          {buyer.verified && (
            <div className="verify-box">
              <Icon name="shield" size={22} />
              <span>
                <b>{T('Comprador verificado por CaféDirecto', 'Verified by CaféDirecto')}</b>
                <small>{P(buyer.verifiedNote)}</small>
              </span>
            </div>
          )}

          <h3 className="section-title">{T('Sobre nosotros', 'About us')}</h3>
          <p className="story">{P(buyer.about)}</p>

          <h3 className="section-title">{T('Qué buscamos', 'What we look for')}</h3>
          <p className="story">{P(buyer.looking)}</p>

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
    </div>
  );
}
