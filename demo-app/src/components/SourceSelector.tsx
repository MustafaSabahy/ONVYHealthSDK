//
//  SourceSelector.tsx
//  Component for switching between data sources
//

import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';
import { DataSource } from '../types';

interface SourceSelectorProps {
  sources: DataSource[];
  currentSource: string;
  onSourceChange: (source: string) => void;
}

const SourceSelector: React.FC<SourceSelectorProps> = ({
  sources,
  currentSource,
  onSourceChange,
}) => {
  const sourceOptions = [
    { id: 'aggregated', name: 'Aggregated', color: '#2A54E5' },
    { id: 'healthkit', name: 'HealthKit', color: '#4CAF50' },
    { id: 'wearable', name: 'Wearable', color: '#FF9800' },
    { id: 'nutrition', name: 'Nutrition', color: '#9C27B0' },
  ];

  return (
    <View style={styles.container}>
      <Text style={styles.label}>Data Source:</Text>
      <View style={styles.selector}>
        {sourceOptions.map((option) => {
          const isSelected = currentSource === option.id;
          return (
            <TouchableOpacity
              key={option.id}
              style={[
                styles.option,
                isSelected && { backgroundColor: option.color },
              ]}
              onPress={() => onSourceChange(option.id)}
            >
              <Text
                style={[
                  styles.optionText,
                  isSelected && styles.optionTextSelected,
                ]}
              >
                {option.name}
              </Text>
            </TouchableOpacity>
          );
        })}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#1a1a1a', // ONVY dark card background
    marginHorizontal: 16,
    marginTop: 16,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 5,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FFFFFF', // ONVY white text
    marginBottom: 8,
  },
  selector: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  option: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    marginRight: 8,
    marginBottom: 8,
  },
  optionText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '500',
  },
  optionTextSelected: {
    color: 'white',
    fontWeight: '600',
  },
});

export default SourceSelector;
