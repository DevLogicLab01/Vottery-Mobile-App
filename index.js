import 'react-native-gesture-handler';
import { enableScreens } from 'react-native-screens';
import { registerRootComponent } from 'expo';
import App from './App';

// Explicitly enable screens for native-stack stability
enableScreens();

// registerRootComponent calls AppRegistry.registerComponent('main', () => App);
registerRootComponent(App);
