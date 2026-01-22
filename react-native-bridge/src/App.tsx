//
//  App.tsx
//  Main demo app entry point
//  Shows complete HealthKit integration
//

import React from 'react';
import { SafeAreaView, StyleSheet } from 'react-native';
import HealthDashboard from './components/HealthDashboard';

const App: React.FC = () => {
  return (
    <SafeAreaView style={styles.container}>
      <HealthDashboard />
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
});

export default App;
