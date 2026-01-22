//
//  expo-plugin-onvy-healthkit/app.plugin.js
//  Expo plugin for ONVY Health SDK
//

const { withInfoPlist, withXcodeProject } = require('@expo/config-plugins');

/**
 * Expo plugin for ONVY Health SDK
 * Adds HealthKit capability and Info.plist entries
 */
function withONVYHealthKit(config) {
  // Add Info.plist entries
  config = withInfoPlist(config, (config) => {
    config.modResults.NSHealthShareUsageDescription =
      'We need access to your health data to provide personalized health insights and track your fitness progress.';
    config.modResults.NSHealthUpdateUsageDescription =
      'We need permission to update your health data to keep your records accurate.';
    config.modResults.NSHealthClinicalHealthRecordsShareUsageDescription =
      'We need access to your clinical health records to provide comprehensive health insights.';
    return config;
  });

  // Add HealthKit capability
  config = withXcodeProject(config, (config) => {
    const xcodeProject = config.modResults;
    const target = xcodeProject.getFirstTarget().uuid;

    // Add HealthKit capability
    xcodeProject.addCapability(target, 'com.apple.HealthKit');

    return config;
  });

  return config;
}

module.exports = withONVYHealthKit;
