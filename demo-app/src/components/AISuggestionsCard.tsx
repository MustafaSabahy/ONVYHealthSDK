//
//  AISuggestionsCard.tsx
//  Component for displaying AI-driven health suggestions
//

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { HealthDataSummary } from '../types';

interface AISuggestionsCardProps {
  summary: HealthDataSummary;
}

const AISuggestionsCard: React.FC<AISuggestionsCardProps> = ({ summary }) => {
  const suggestions = generateSuggestions(summary);

  if (suggestions.length === 0) {
    return null;
  }

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.icon}>🤖</Text>
        <Text style={styles.title}>AI Health Suggestions</Text>
      </View>
      {suggestions.map((suggestion, index) => (
        <View key={index} style={styles.suggestion}>
          <Text style={styles.suggestionText}>{suggestion}</Text>
        </View>
      ))}
    </View>
  );
};

// Generate AI-driven suggestions based on health data
function generateSuggestions(summary: HealthDataSummary): string[] {
  const suggestions: string[] = [];
  const targetSteps = 10000;

  // Steps suggestions
  if (summary.steps < targetSteps) {
    const remaining = Math.round(targetSteps - summary.steps);
    suggestions.push(`Take ${remaining.toLocaleString()} more steps today to reach your goal`);
  } else {
    suggestions.push('Great job! You\'ve reached your daily step goal 🎉');
  }

  // Heart rate suggestions
  if (summary.averageHeartRate) {
    if (summary.averageHeartRate < 60) {
      suggestions.push('Your resting heart rate is low. Consider light activity to maintain cardiovascular health');
    } else if (summary.averageHeartRate > 100) {
      suggestions.push('Your heart rate is elevated. Take time to rest and recover');
    } else {
      suggestions.push('Your heart rate is in a healthy range. Keep up the good work!');
    }
  }

  // Sleep suggestions
  if (summary.sleepHours) {
    if (summary.sleepHours < 7) {
      suggestions.push(`Aim for ${(7 - summary.sleepHours).toFixed(1)} more hours of sleep tonight for optimal recovery`);
    } else if (summary.sleepHours >= 7 && summary.sleepHours <= 9) {
      suggestions.push('You\'re getting optimal sleep. Maintain this routine!');
    } else {
      suggestions.push('You\'re getting plenty of sleep. Consider if you need this much rest');
    }
  }

  return suggestions.slice(0, 3); // Limit to 3 suggestions
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#1a1a1a', // ONVY dark card background
    borderRadius: 16,
    padding: 20,
    margin: 16,
    marginTop: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
    borderLeftWidth: 4,
    borderLeftColor: '#FFD700', // ONVY gold accent
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
    color: '#FFFFFF', // ONVY white text
  },
  suggestion: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.05)', // Subtle dark background
    borderRadius: 8,
    marginBottom: 8,
  },
  suggestionText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)', // ONVY light text
    lineHeight: 20,
  },
});

export default AISuggestionsCard;
