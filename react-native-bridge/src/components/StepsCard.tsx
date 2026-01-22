//
//  StepsCard.tsx
//  Component for displaying steps data with animations
//

import React, { useEffect, useRef } from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';

interface StepsCardProps {
  steps: number;
  animated?: boolean;
}

const StepsCard: React.FC<StepsCardProps> = ({ steps, animated = false }) => {
  const animatedValue = useRef(new Animated.Value(0)).current;
  const previousSteps = useRef(steps);

  useEffect(() => {
    if (animated && steps !== previousSteps.current) {
      // Animate value change
      Animated.timing(animatedValue, {
        toValue: steps,
        duration: 500,
        useNativeDriver: false,
      }).start();
      
      previousSteps.current = steps;
    } else {
      animatedValue.setValue(steps);
    }
  }, [steps, animated]);

  const displaySteps = animated
    ? animatedValue.interpolate({
        inputRange: [0, 50000],
        outputRange: [0, 50000],
        extrapolate: 'clamp',
      })
    : steps;

  const formattedSteps = animated
    ? (displaySteps as Animated.AnimatedAddition).__getValue()
    : Math.round(steps);

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <Text style={styles.icon}>👣</Text>
        <Text style={styles.title}>Steps</Text>
      </View>
      {animated ? (
        <Animated.Text style={styles.value}>
          {Math.round((displaySteps as any).__getValue() || 0).toLocaleString()}
        </Animated.Text>
      ) : (
        <Text style={styles.value}>{Math.round(steps).toLocaleString()}</Text>
      )}
      <Text style={styles.label}>Today</Text>
      <View style={styles.progressBar}>
        <View
          style={[
            styles.progressFill,
            { width: `${Math.min((steps / 10000) * 100, 100)}%` },
          ]}
        />
      </View>
      <Text style={styles.goalText}>
        Goal: 10,000 steps ({Math.round((steps / 10000) * 100)}%)
      </Text>
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#4CAF50', // Green color for steps
    borderRadius: 12,
    padding: 20,
    margin: 16,
    marginBottom: 0,
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
    marginBottom: 12,
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 8,
  },
  progressFill: {
    height: '100%',
    backgroundColor: 'white',
    borderRadius: 4,
  },
  goalText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
  },
});

export default StepsCard;
