//
//  HeartRateCard.tsx
//  Component for displaying heart rate data with animations
//

import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';

interface HeartRateCardProps {
  heartRate: number | null;
  animated?: boolean;
}

const HeartRateCard: React.FC<HeartRateCardProps> = ({
  heartRate,
  animated = false,
}) => {
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const animatedValue = useRef(new Animated.Value(heartRate || 0)).current;

  useEffect(() => {
    if (animated && heartRate !== null) {
      // Pulse animation
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.2,
            duration: 500,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 500,
            useNativeDriver: true,
          }),
        ])
      ).start();

      // Value animation
      Animated.timing(animatedValue, {
        toValue: heartRate,
        duration: 300,
        useNativeDriver: false,
      }).start();
    }
  }, [heartRate, animated]);

  const getHeartRateColor = (hr: number | null): string => {
    if (hr === null) return '#2196F3'; // Blue for no data
    if (hr < 60) return '#9C27B0'; // Purple for low
    if (hr > 100) return '#F44336'; // Red for high
    return '#2196F3'; // Blue for normal
  };

  const getHeartRateStatus = (hr: number | null): string => {
    if (hr === null) return 'No data';
    if (hr < 60) return 'Low';
    if (hr > 100) return 'Elevated';
    return 'Normal';
  };

  return (
    <View style={[styles.card, { backgroundColor: getHeartRateColor(heartRate) }]}>
      <View style={styles.header}>
        <Animated.View style={{ transform: [{ scale: pulseAnim }] }}>
          <Text style={styles.icon}>❤️</Text>
        </Animated.View>
        <Text style={styles.title}>Heart Rate</Text>
      </View>
      {heartRate !== null ? (
        <>
          {animated ? (
            <Animated.Text style={styles.value}>
              {Math.round((animatedValue as any).__getValue() || 0)}
            </Animated.Text>
          ) : (
            <Text style={styles.value}>{Math.round(heartRate)}</Text>
          )}
          <Text style={styles.label}>
            {getHeartRateStatus(heartRate)} (bpm)
          </Text>
        </>
      ) : (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>No data available</Text>
          <Text style={styles.emptySubtext}>
            Heart rate data will appear here when available
          </Text>
        </View>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    borderRadius: 12,
    padding: 20,
    margin: 16,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  icon: {
    fontSize: 24,
    marginRight: 8,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: 'white',
  },
  value: {
    fontSize: 48,
    fontWeight: 'bold',
    color: 'white',
    marginBottom: 4,
  },
  label: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
  },
  emptyState: {
    paddingVertical: 20,
  },
  emptyText: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.9)',
    marginBottom: 4,
  },
  emptySubtext: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
});

export default HeartRateCard;
