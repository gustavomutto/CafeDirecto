import { matchPath, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { useApp } from './context/AppContext';
import PhoneFrame from './components/PhoneFrame';
import TabBar from './components/TabBar';
import DemoPanel from './components/DemoPanel';

import Onboarding from './screens/Onboarding';
import FarmerHome from './screens/FarmerHome';
import Explore from './screens/Explore';
import LotDetail from './screens/LotDetail';
import FarmProfile from './screens/FarmProfile';
import BuyerProfile from './screens/BuyerProfile';
import MyProfile from './screens/MyProfile';
import PublishLot from './screens/PublishLot';
import ChatList from './screens/ChatList';
import ChatRoom from './screens/ChatRoom';
import Orders from './screens/Orders';
import OrderDetail from './screens/OrderDetail';
import RateAgreement from './screens/RateAgreement';
import Learn from './screens/Learn';
import LearnDetail from './screens/LearnDetail';
import Fees from './screens/Fees';

// Pantallas donde se oculta la barra inferior (para dar espacio a formularios y chat)
const NO_TABS = ['/welcome', '/chat/:id', '/publish', '/rate/:id'];

function Home() {
  const { role } = useApp();
  return role === 'farmer' ? <FarmerHome /> : <Explore />;
}

export default function App() {
  const { state } = useApp();
  const location = useLocation();
  const showTabs = !NO_TABS.some((p) => matchPath(p, location.pathname));

  let content;
  if (!state.onboarded && location.pathname !== '/welcome') {
    content = <Navigate to="/welcome" replace />;
  } else {
    content = (
      // La "key" fuerza la animación de entrada en cada cambio de pantalla
      <div className="route-anim" key={location.pathname}>
        <Routes location={location}>
          <Route path="/welcome" element={<Onboarding />} />
          <Route path="/home" element={<Home />} />
          <Route path="/lot/:id" element={<LotDetail />} />
          <Route path="/farm/:id" element={<FarmProfile />} />
          <Route path="/buyer/:id" element={<BuyerProfile />} />
          <Route path="/me" element={<MyProfile />} />
          <Route path="/publish" element={<PublishLot />} />
          <Route path="/chats" element={<ChatList />} />
          <Route path="/chat/:id" element={<ChatRoom />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/orders/:id" element={<OrderDetail />} />
          <Route path="/rate/:id" element={<RateAgreement />} />
          <Route path="/learn" element={<Learn />} />
          <Route path="/learn/:id" element={<LearnDetail />} />
          <Route path="/fees" element={<Fees />} />
          <Route path="*" element={<Navigate to="/home" replace />} />
        </Routes>
      </div>
    );
  }

  return (
    <div className="stage">
      <div className="stage-glow" />
      <PhoneFrame tabBar={showTabs && state.onboarded ? <TabBar /> : null}>{content}</PhoneFrame>
      <DemoPanel />
    </div>
  );
}
