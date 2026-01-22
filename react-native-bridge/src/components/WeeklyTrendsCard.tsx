//
//  WeeklyTrendsCard.tsx
//  Component for displaying weekly health trends
//

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { WeeklyTrend } from '../ONVYHealthKit';

interface WeeklyTrendsCardProps {
  trends: WeeklyTrend[];
}

const WeeklyTrendsCard: React.FC<WeeklyTrendsCardProps> = ({ trends }) => {
  if (trends.length === 0) {
    return null;
  }

  // Calculate averages
  const avgSteps = trends.reduce((sum, t) => sum + t.steps, 0) / trends.length;
  const avgHeartRate = trends
    .filter((t) => t.averageHeartRate !== null)
    .reduce((sum, t) => sum + (t.averageHeartRate || 0), 0) /
    trends.filter((t) => t.averageHeartRate !== null).length;
  const avgSleep = trends
    .filter((t) => t.sleepHours !== null)
    .reduce((sum, t) => sum + (t.sleepHours || 0), 0) /
    trends.filter((t) => t.sleepHours !== null).length;

  // Find best day
  const bestDay = trends.reduce((best, current) =>
    current.steps > best.steps ? current : best
  );

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.icon}>📊</Text>
        <Text style={styles.title}>Weekly Trends</Text>
      </View>

      <View style={styles.stats}>
        <View style={styles.stat}>
          <Text style={styles.statValue}>{Math.round(avgSteps).toLocaleString()}</Text>
          <Text style={styles.statLabel}>Avg Steps/Day</Text>
        </View>
        {avgHeartRate > 0 && (
          <View style={styles.stat}>
            <Text style={styles.statValue}>{Math.round(avgHeartRate)}</Text>
            <Text style={styles.statLabel}>Avg HR (bpm)</Text>
          </View>
        )}
        {avgSleep > 0 && (
          <View style={styles.stat}>
            <Text style={styles.statValue}>{avgSleep.toFixed(1)}h</Text>
            <Text style={styles.statLabel}>Avg Sleep</Text>
          </View>
        )}
      </View>

      <View style={styles.bestDay}>
        <Text style={styles.bestDayLabel}>Best Day:</Text>
        <Text style={styles.bestDayValue}>
          {new Date(bestDay.date).toLocaleDateString('en-US', {
            weekday: 'short',
          })}{' '}
          - {Math.round(bestDay.steps).toLocaleString()} steps
        </Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: 'white',
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
    marginBottom: 16,
  },
  icon: {
    fontSize: 24,
    marginRight: 8,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
  },
  stats: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 16,
    borderTopWidth: 1,
    borderTopColor: '#f0f0f0',
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  stat: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#2A54E5',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 12,
    color: '#999',
  },
  bestDay: {
    marginTop: 16,
    padding: 12,
    backgroundColor: '#f8f9fa',
    borderRadius: 8,
  },
  bestDayLabel: {
    fontSize: 12,
    color: '#666',
    marginBottom: 4,
  },
  bestDayValue: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
});

export default WeeklyTrendsCard;
