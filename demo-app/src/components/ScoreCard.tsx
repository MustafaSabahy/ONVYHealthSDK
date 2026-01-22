//
//  ScoreCard.tsx
//  ONVY-style score card with semi-circular progress indicator
//  Inspired by ONVY's "Scores" dashboard design
//

import React from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';

interface ScoreCardProps {
  title: string;
  score: number;
  icon: string;
  color?: string; // Optional accent color
  maxScore?: number;
}

const { width } = Dimensions.get('window');
const cardWidth = (width - 48) / 2; // 2 columns with margins

const ScoreCard: React.FC<ScoreCardProps> = ({
  title,
  score,
  icon,
  color,
  maxScore = 100,
}) => {
  const percentage = Math.min((score / maxScore) * 100, 100);

  // Determine status color based on score (ONVY style)
  const getStatusColor = (): string => {
    if (score >= 70) return '#4CAF50'; // Green for good
    if (score >= 40) return '#FFA726'; // Orange/Yellow for moderate
    return '#F44336'; // Red for low
  };

  const statusColor = getStatusColor();

  return (
    <View style={styles.card}>
      <View style={styles.iconContainer}>
        <Text style={styles.icon}>{icon}</Text>
      </View>
      
      <View style={styles.scoreContainer}>
        <Text style={styles.score}>{Math.round(score)}</Text>
      </View>

      {/* Simplified progress indicator - colored border */}
      <View style={styles.progressContainer}>
        <View style={[styles.progressBar, { width: `${percentage}%`, backgroundColor: statusColor }]} />
      </View>

      <Text style={styles.title}>{title}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    width: cardWidth,
    aspectRatio: 1,
    borderRadius: 16,
    padding: 16,
    margin: 8,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#1a1a1a', // Dark card background
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  iconContainer: {
    marginTop: 8,
    marginBottom: 4,
  },
  icon: {
    fontSize: 32,
  },
  scoreContainer: {
    marginBottom: 8,
  },
  score: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  progressContainer: {
    width: '80%',
    height: 4,
    marginBottom: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 2,
    overflow: 'hidden',
  },
  progressBar: {
    height: '100%',
    borderRadius: 2,
  },
  title: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF',
    marginTop: 4,
  },
});

export default ScoreCard;
