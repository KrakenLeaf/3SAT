/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker.tracker;

import eu.anorien.mhl.Fact;
import eu.anorien.mhl.Hypothesis;
import eu.anorien.mhl.lisbonimpl.LHypothesis;
import java.util.ArrayList;
import java.util.List;
import org.apache.log4j.Logger;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class MTracker {

    private static final Logger logger = Logger.getLogger(MTracker.class);
    private Tracker tracker;

    public MTracker(
            int maxNumLeaves,
            int maxDepth,
            int timeUndetected,
            int bestK,
            double probUndetected,
            double probNewTarget,
            double probFalseAlarm,
            double gateSize) {
        this.tracker = new Tracker(maxNumLeaves, maxDepth, timeUndetected, bestK, probUndetected, probNewTarget, probFalseAlarm, gateSize);
    }

    public double[][] newScan(double[][] measurements) {
        if (measurements == null) {
            return new double[0][0];
        }
        List<Measurement> points = new ArrayList<Measurement>();
        for (int i = 0; i < measurements.length; i++) {
            double[] row = measurements[i];
            points.add(new Measurement(row[0], row[1], 0, 0));
        }
        tracker.newScan(points);
//        System.out.println("Measurements:");
//        for (Point2D point2D : points) {
//            System.out.println("\t" + point2D.getX() + " " + point2D.getY());
//        }
        Hypothesis best = tracker.getBestHypothesis();
        double[][] targets = new double[best.getFacts().size()][4];
        int i = 0;
//        System.out.println("Targets:");
        for (Fact fact : best.getFacts().keySet()) {
//            System.out.println("\t" + ((TargetFact) fact).getX() + " " + ((TargetFact) fact).getY());
            targets[i][0] = ((TargetFact) fact).getBoundingBox()[0];
            targets[i][1] = ((TargetFact) fact).getBoundingBox()[1];
//            targets[i][2] = ((TargetFact) fact).getBoundingBox()[2];
//            targets[i][3] = ((TargetFact) fact).getBoundingBox()[3];
            targets[i][2] = ((TargetFact) fact).getId();
            targets[i][3] = ((LHypothesis) best).getFactClusterIdMap().get(fact);
            i++;
        }
        return targets;
    }
}
