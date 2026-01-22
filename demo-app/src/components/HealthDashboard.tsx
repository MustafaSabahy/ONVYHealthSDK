//
//  HealthDashboard.tsx
//  Dashboard that works with both real HealthKit and mock data
//

import React, { useEffect, useState, useCallback, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  RefreshControl,
  Alert,
  ActivityIndicator,
  TouchableOpacity,
  Animated,
  Platform,
} from 'react-native';

// Use mock data for Simulator (HealthKit doesn't work on Simulator)
import ONVYHealthKit from '../services/ONVYHealthKitMock';

import StepsCard from './StepsCard';
import HeartRateCard from './HeartRateCard';
import SleepCard from './SleepCard';
import WeeklyTrendsCard from './WeeklyTrendsCard';
import AISuggestionsCard from './AISuggestionsCard';
import SourceSelector from './SourceSelector';
import ScoreCard from './ScoreCard';

interface HealthDashboardProps {
  useMockData?: boolean;
}

const HealthDashboard: React.FC<HealthDashboardProps> = ({ useMockData: forceMock = false }) => {
  const [summary, setSummary] = useState<any>(null);
  const [weeklyTrends, setWeeklyTrends] = useState<any[]>([]);
  const [authorized, setAuthorized] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [availableSources, setAvailableSources] = useState<any[]>([]);
  const [currentSource, setCurrentSource] = useState<string>('aggregated');
  const [liveUpdateCount, setLiveUpdateCount] = useState<number>(0);
  const [isSimulator, setIsSimulator] = useState<boolean>(forceMock || (Platform.OS === 'ios' && !Platform.isPad));
  
  const pulseAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    checkAuthorization();
    loadAvailableSources();
  }, []);

  useEffect(() => {
    if (authorized) {
      loadData();
      setupObservers();
    }
  }, [authorized, currentSource]);

  useEffect(() => {
    if (liveUpdateCount > 0) {
      Animated.sequence([
        Animated.timing(pulseAnim, {
          toValue: 1.1,
          duration: 200,
          useNativeDriver: true,
        }),
        Animated.timing(pulseAnim, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true,
        }),
      ]).start();
    }
  }, [liveUpdateCount]);

  const checkAuthorization = async () => {
    try {
      const status = await ONVYHealthKit.checkAuthorizationStatus();
      const isAuthorized = Object.values(status.status || {}).some(
        (s: any) => s === 'authorized'
      );
      setAuthorized(isAuthorized || isSimulator); // Auto-authorize for Simulator
    } catch (error: any) {
      console.error('Authorization check error:', error);
      if (isSimulator) {
        setAuthorized(true); // Auto-authorize for Simulator
      }
    } finally {
      setLoading(false);
    }
  };

  const loadAvailableSources = async () => {
    try {
      const sources = await ONVYHealthKit.getAvailableSources();
      setAvailableSources(sources);
    } catch (error) {
      console.error('Failed to load sources:', error);
    }
  };

  const requestAuthorization = async () => {
    try {
      setLoading(true);
      const result = await ONVYHealthKit.requestAuthorization();
      setAuthorized(true);
      await loadData();
      setupObservers();
    } catch (error: any) {
      console.error('Authorization error:', error);
      if (isSimulator) {
        setAuthorized(true);
        await loadData();
        setupObservers();
      } else {
        Alert.alert('Error', `Failed to request authorization: ${error.message}`);
      }
    } finally {
      setLoading(false);
    }
  };

  const loadData = async () => {
    try {
      await ONVYHealthKit.setDataSource(currentSource);
      
      const [data, trends] = await Promise.all([
        ONVYHealthKit.getHealthDataSummary(),
        ONVYHealthKit.getWeeklyTrends().catch(() => ({ data: [] })),
      ]);
      
      setSummary(data);
      setWeeklyTrends(trends.data || []);
    } catch (error: any) {
      console.error('Load data error:', error);
      // For Simulator, use mock data
      if (isSimulator) {
        setSummary({
          date: Date.now(),
          steps: 8500,
          averageHeartRate: 72,
          sleepHours: 7.5,
          activeCalories: 450,
          sources: ['Mock Wearable', 'Mock Nutrition'],
        });
      } else {
        Alert.alert('Error', `Failed to load health data: ${error.message}`);
      }
    }
  };

  const setupObservers = () => {
    const unsubscribeSteps = ONVYHealthKit.subscribeToSteps((data: any) => {
      setLiveUpdateCount((prev) => prev + 1);
      if (summary) {
        setSummary({
          ...summary,
          steps: data.value,
        });
      }
    });

    const unsubscribeHeartRate = ONVYHealthKit.subscribeToHeartRate((data: any) => {
      setLiveUpdateCount((prev) => prev + 1);
      if (summary && data.heartRate) {
        setSummary({
          ...summary,
          averageHeartRate: data.heartRate,
        });
      }
    });

    const unsubscribeLive = ONVYHealthKit.subscribeToLiveUpdates((data: any) => {
      setLiveUpdateCount((prev) => prev + 1);
      if (summary) {
        setSummary({
          ...summary,
          steps: data.steps,
          averageHeartRate: data.heartRate > 0 ? data.heartRate : summary.averageHeartRate,
        });
      }
    });

    return () => {
      unsubscribeSteps();
      unsubscribeHeartRate();
      unsubscribeLive();
    };
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      await loadData();
    } catch (error) {
      console.error('Refresh error:', error);
    } finally {
      setRefreshing(false);
    }
  }, [currentSource]);

  const handleSourceChange = async (source: string) => {
    try {
      await ONVYHealthKit.setDataSource(source);
      setCurrentSource(source);
      await loadData();
    } catch (error: any) {
      Alert.alert('Error', `Failed to switch source: ${error.message}`);
    }
  };

  const sendToBackend = async () => {
    try {
      const result = await ONVYHealthKit.sendHealthDataToBackend();
      if (result.success) {
        Alert.alert('Success', 'Health data sent to backend successfully');
      }
    } catch (error: any) {
      Alert.alert('Error', `Failed to send data: ${error.message}`);
    }
  };

  if (loading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#2A54E5" />
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  if (!authorized) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.title}>Health Data Access Required</Text>
        <Text style={styles.message}>
          To view your health data, we need access to HealthKit. This allows us to
          display your steps, heart rate, and sleep data from multiple sources.
        </Text>
        {isSimulator && (
          <View style={styles.simulatorNotice}>
            <Text style={styles.simulatorText}>
              ⚠️ Running on Simulator - Using Mock Data
            </Text>
            <Text style={styles.simulatorSubtext}>
              HealthKit requires a physical device. This demo uses simulated data.
            </Text>
          </View>
        )}
        <TouchableOpacity style={styles.button} onPress={requestAuthorization}>
          <Text style={styles.buttonText}>Request Authorization</Text>
        </TouchableOpacity>
      </View>
    );
  }

  if (!summary) {
    return (
      <View style={styles.centerContainer}>
        <Text style={styles.message}>No health data available</Text>
        <TouchableOpacity style={styles.button} onPress={loadData}>
          <Text style={styles.buttonText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  // Calculate ONVY-style scores from health data
  const calculateScores = () => {
    // Recovery Score (0-100): Based on sleep and heart rate
    const recoveryScore = summary.sleepHours
      ? Math.min(100, Math.round((summary.sleepHours / 9) * 100 + (summary.averageHeartRate ? (100 - summary.averageHeartRate) / 2 : 0)))
      : 50;

    // Activity Score (0-100): Based on steps
    const activityScore = Math.min(100, Math.round((summary.steps / 10000) * 100));

    // Sleep Score (0-100): Based on sleep hours
    const sleepScore = summary.sleepHours
      ? Math.min(100, Math.round((summary.sleepHours / 9) * 100))
      : 50;

    // Mind Score (0-100): Mock calculation (could be based on HRV, stress, etc.)
    const mindScore = Math.max(10, Math.min(100, recoveryScore - 20));

    return { recoveryScore, activityScore, sleepScore, mindScore };
  };

  const scores = calculateScores();

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl 
          refreshing={refreshing} 
          onRefresh={onRefresh}
          tintColor="#FFFFFF"
        />
      }
    >
      {isSimulator && (
        <View style={styles.simulatorBanner}>
          <Text style={styles.simulatorBannerText}>
            📱 Simulator Mode - Using Mock Data
          </Text>
        </View>
      )}
      
      {/* ONVY-style Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Scores</Text>
        {liveUpdateCount > 0 && (
          <Animated.View style={[styles.liveIndicator, { transform: [{ scale: pulseAnim }] }]}>
            <Text style={styles.liveText}>● LIVE</Text>
          </Animated.View>
        )}
      </View>

      {/* ONVY-style 2x2 Scores Grid */}
      <View style={styles.scoresGrid}>
        <ScoreCard
          title="Recovery"
          score={scores.recoveryScore}
          icon="⚡"
        />
        <ScoreCard
          title="Activity"
          score={scores.activityScore}
          icon="🏃"
        />
        <ScoreCard
          title="Sleep"
          score={scores.sleepScore}
          icon="😴"
        />
        <ScoreCard
          title="Mind"
          score={scores.mindScore}
          icon="🧠"
        />
      </View>

      {/* Detailed Metrics Section */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Today's Metrics</Text>
        <Text style={styles.sectionSubtitle}>
          {new Date(summary.date).toLocaleDateString('en-US', { 
            weekday: 'long', 
            month: 'long', 
            day: 'numeric' 
          })}
        </Text>
      </View>

      <StepsCard steps={summary.steps} animated />
      <HeartRateCard heartRate={summary.averageHeartRate} animated />
      <SleepCard sleepHours={summary.sleepHours} animated />

      {weeklyTrends.length > 0 && (
        <WeeklyTrendsCard trends={weeklyTrends} />
      )}

      <AISuggestionsCard summary={summary} />

      <View style={styles.actionContainer}>
        <TouchableOpacity style={styles.actionButton} onPress={sendToBackend}>
          <Text style={styles.actionButtonText}>Send Data to Backend</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000', // ONVY dark theme
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#000000', // ONVY dark theme
  },
  simulatorBanner: {
    backgroundColor: '#FF9800',
    padding: 12,
    alignItems: 'center',
  },
  simulatorBannerText: {
    color: 'white',
    fontWeight: '600',
    fontSize: 12,
  },
  simulatorNotice: {
    backgroundColor: '#FFF3CD',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
    width: '100%',
  },
  simulatorText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#856404',
    marginBottom: 4,
  },
  simulatorSubtext: {
    fontSize: 12,
    color: '#856404',
  },
  header: {
    padding: 24,
    paddingTop: 32,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#FFFFFF', // ONVY white text
  },
  liveIndicator: {
    backgroundColor: '#4CAF50',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 12,
  },
  liveText: {
    color: 'white',
    fontSize: 11,
    fontWeight: 'bold',
  },
  scoresGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    paddingHorizontal: 8,
    marginBottom: 24,
  },
  sectionHeader: {
    paddingHorizontal: 24,
    paddingTop: 8,
    marginBottom: 8,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  sectionSubtitle: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF', // ONVY white text
    marginBottom: 16,
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)', // ONVY light text
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 24,
  },
  button: {
    backgroundColor: '#FFD700', // ONVY gold accent
    padding: 16,
    borderRadius: 12,
    minWidth: 200,
  },
  buttonText: {
    color: '#000000',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  actionContainer: {
    padding: 20,
    paddingBottom: 40,
  },
  actionButton: {
    backgroundColor: '#FFD700', // ONVY gold accent
    padding: 16,
    borderRadius: 12,
  },
  actionButtonText: {
    color: '#000000',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
});

export default HealthDashboard;
