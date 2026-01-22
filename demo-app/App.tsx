//
//  App.tsx
//  ONVY Health SDK Demo App
//  Works on iOS Simulator with mock data
//

import React from 'react';
import { SafeAreaView, StyleSheet, Platform } from 'react-native';
import HealthDashboard from './src/components/HealthDashboard';

export default function App() {
  // Note: HealthKit requires physical device
  // This demo uses mock data for Simulator
  const isSimulator = Platform.OS === 'ios' && !Platform.isPad && !Platform.isTV;
  
  return (
    <SafeAreaView style={styles.container}>
      <HealthDashboard useMockData={isSimulator} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000', // ONVY dark theme
  },
});
