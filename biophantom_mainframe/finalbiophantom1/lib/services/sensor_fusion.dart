class SensorFusionService {
  // Simulate sensor fusion AI for risk scoring
  double getRiskScore(double vibProb, double audProb) {
    // Simple fusion: weighted average
    return (0.6 * vibProb) + (0.4 * audProb);
  }
}
