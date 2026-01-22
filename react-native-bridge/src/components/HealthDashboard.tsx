//
//  HealthDashboard.tsx
//  Dashboard with multiple sources, AI suggestions, and live updates
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
} from 'react-native';
import ONVYHealthKit, {
  HealthDataSummary,
  AuthorizationStatus,
  DataSource,
  WeeklyTrend,
  LiveUpdate,
} from '../ONVYHealthKit';
import StepsCard from './StepsCard';
import HeartRateCard from './HeartRateCard';
import SleepCard from './SleepCard';
import WeeklyTrendsCard from './WeeklyTrendsCard';
import AISuggestionsCard from './AISuggestionsCard';
import SourceSelector from './SourceSelector';

const HealthDashboard: React.FC = () => {
  const [summary, setSummary] = useState<HealthDataSummary | null>(null);
  const [weeklyTrends, setWeeklyTrends] = useState<WeeklyTrend[]>([]);
  const [authorized, setAuthorized] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [authStatus, setAuthStatus] = useState<AuthorizationStatus | null>(null);
  const [availableSources, setAvailableSources] = useState<DataSource[]>([]);
  const [currentSource, setCurrentSource] = useState<string>('aggregated');
  const [liveUpdateCount, setLiveUpdateCount] = useState<number>(0);
  
  // Animation values for live updates
  const pulseAnim = useRef(new Animated.Value(1)).current;

  // Check authorization on mount
  useEffect(() => {
    checkAuthorization();
    loadAvailableSources();
  }, []);

  // Load data when authorized
  useEffect(() => {
    if (authorized) {
      loadData();
      setupObservers();
    }
  }, [authorized, currentSource]);

  // Pulse animation for live updates
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
      setAuthStatus(status);
      
      // Check if at least one source is authorized
      const isAuthorized = Object.values(status.status || {}).some(
        (s) => s === 'authorized'
      );
      setAuthorized(isAuthorized);
    } catch (error: any) {
      console.error('Authorization check error:', error);
      Alert.alert('Error', 'Failed to check authorization status');
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
      setAuthStatus(result);
      
      const isAuthorized = Object.values(result.status || {}).some(
        (s) => s === 'authorized'
      );
      setAuthorized(isAuthorized);
      
      if (isAuthorized) {
        await loadData();
        setupObservers();
      } else {
        Alert.alert(
          'Authorization Denied',
          'Please enable HealthKit access in Settings > Privacy & Security > Health'
        );
      }
    } catch (error: any) {
      console.error('Authorization error:', error);
      
      // Handle different error scenarios
      if (error.message.includes('NOT_AVAILABLE')) {
        Alert.alert(
          'HealthKit Not Available',
          'HealthKit requires a physical iOS device. The simulator does not support HealthKit.'
        );
      } else if (error.message.includes('AUTHORIZATION_DENIED')) {
        Alert.alert(
          'Authorization Denied',
          'Please enable HealthKit access in Settings > Privacy & Security > Health'
        );
      } else {
        Alert.alert('Error', `Failed to request authorization: ${error.message}`);
      }
    } finally {
      setLoading(false);
    }
  };

  const loadData = async () => {
    try {
      // Set data source before loading
      await ONVYHealthKit.setDataSource(currentSource);
      
      const [data, trends] = await Promise.all([
        ONVYHealthKit.getHealthDataSummary(),
        ONVYHealthKit.getWeeklyTrends().catch(() => []), // Don't fail if trends unavailable
      ]);
      
      setSummary(data);
      setWeeklyTrends(trends);
    } catch (error: any) {
      console.error('Load data error:', error);
      
      // Handle different error scenarios
      if (error.message.includes('AUTHORIZATION_DENIED')) {
        Alert.alert(
          'Authorization Required',
          'HealthKit authorization is required to view health data.'
        );
        setAuthorized(false);
      } else if (error.message.includes('NO_DATA_AVAILABLE')) {
        // No data is not an error, just show empty state
        setSummary({
          date: Date.now(),
          steps: 0,
          averageHeartRate: null,
          sleepHours: null,
          activeCalories: null,
        });
      } else if (error.message.includes('NOT_AVAILABLE')) {
        Alert.alert(
          'Device Not Supported',
          'HealthKit is not available on this device. Using mock data for demo.'
        );
        // Use mock data
        setSummary({
          date: Date.now(),
          steps: 8500,
          averageHeartRate: 72,
          sleepHours: 7.5,
          activeCalories: 450,
        });
      } else {
        Alert.alert('Error', `Failed to load health data: ${error.message}`);
      }
    }
  };

  const setupObservers = () => {
    // Subscribe to steps updates
    const unsubscribeSteps = ONVYHealthKit.subscribeToSteps((data) => {
      console.log('Steps updated:', data.value);
      setLiveUpdateCount((prev) => prev + 1);
      
      if (summary) {
        setSummary({
          ...summary,
          steps: data.value,
        });
      }
    });

    // Subscribe to heart rate updates
    const unsubscribeHeartRate = ONVYHealthKit.subscribeToHeartRate((data) => {
      console.log('Heart rate updated:', data.heartRate);
      setLiveUpdateCount((prev) => prev + 1);
      
      if (summary && data.heartRate) {
        setSummary({
          ...summary,
          averageHeartRate: data.heartRate,
        });
      }
    });

    // Subscribe to live updates (simulated)
    const unsubscribeLive = ONVYHealthKit.subscribeToLiveUpdates((data) => {
      console.log('Live update:', data);
      setLiveUpdateCount((prev) => prev + 1);
      
      if (summary) {
        setSummary({
          ...summary,
          steps: data.steps,
          averageHeartRate: data.heartRate > 0 ? data.heartRate : summary.averageHeartRate,
        });
      }
    });

    // Subscribe to source changes
    const unsubscribeSource = ONVYHealthKit.subscribeToSourceChange((source) => {
      console.log('Source changed:', source);
      setCurrentSource(source);
      loadData();
    });

    // Cleanup on unmount
    return () => {
      unsubscribeSteps();
      unsubscribeHeartRate();
      unsubscribeLive();
      unsubscribeSource();
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
        <TouchableOpacity style={styles.button} onPress={requestAuthorization}>
          <Text style={styles.buttonText}>Request Authorization</Text>
        </TouchableOpacity>
        {authStatus && (
          <View style={styles.statusContainer}>
            <Text style={styles.statusTitle}>Current Status:</Text>
            {Object.entries(authStatus.status || {}).map(([key, value]) => (
              <Text key={key} style={styles.statusText}>
                {key}: {value}
              </Text>
            ))}
          </View>
        )}
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

  return (
    <ScrollView
      style={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
      }
    >
      <View style={styles.header}>
        <View style={styles.headerTop}>
          <Text style={styles.headerTitle}>Health Dashboard</Text>
          {liveUpdateCount > 0 && (
            <Animated.View style={[styles.liveIndicator, { transform: [{ scale: pulseAnim }] }]}>
              <Text style={styles.liveText}>● LIVE</Text>
            </Animated.View>
          )}
        </View>
        <Text style={styles.headerSubtitle}>
          {new Date(summary.date).toLocaleDateString()}
        </Text>
        {summary.sources && summary.sources.length > 0 && (
          <Text style={styles.sourcesText}>
            Sources: {summary.sources.join(', ')}
          </Text>
        )}
      </View>

      <SourceSelector
        sources={availableSources}
        currentSource={currentSource}
        onSourceChange={handleSourceChange}
      />

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
    backgroundColor: '#f5f5f5',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  header: {
    padding: 20,
    backgroundColor: 'white',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  headerTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
  },
  liveIndicator: {
    backgroundColor: '#4CAF50',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },
  liveText: {
    color: 'white',
    fontSize: 10,
    fontWeight: 'bold',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#666',
    marginBottom: 4,
  },
  sourcesText: {
    fontSize: 12,
    color: '#999',
    fontStyle: 'italic',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
    textAlign: 'center',
  },
  message: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 24,
  },
  button: {
    backgroundColor: '#2A54E5',
    padding: 16,
    borderRadius: 8,
    minWidth: 200,
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  loadingText: {
    marginTop: 16,
    fontSize: 16,
    color: '#666',
  },
  statusContainer: {
    marginTop: 24,
    padding: 16,
    backgroundColor: 'white',
    borderRadius: 8,
    width: '100%',
  },
  statusTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  statusText: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  actionContainer: {
    padding: 20,
  },
  actionButton: {
    backgroundColor: '#2A54E5',
    padding: 16,
    borderRadius: 8,
  },
  actionButtonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
});

export default HealthDashboard;
