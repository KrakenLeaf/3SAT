/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker.tracker;

import eu.anorien.mhl.Fact;
import java.awt.geom.Point2D;
import org.apache.log4j.Logger;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class TargetFact implements Fact {

    private static final Logger logger = Logger.getLogger(TargetFact.class);
    private final long id;
    private final long lastDetection;
    private final double[] boundingBox;
    private final double x, y, velocityX, velocityY;
    private final double gate;

    public TargetFact(double gate, long id, long lastDetection, double x, double y, double velocityX, double velocityY, double[] boundingBox) {
        this.id = id;
        this.lastDetection = lastDetection;
        this.boundingBox = boundingBox;
        this.x = x;
        this.y = y;
        this.velocityX = velocityX;
        this.velocityY = velocityY;
        this.gate = gate;
    }

    public boolean measurementInGate(Measurement measurement) {
        return new Point2D.Double(measurement.getX(), measurement.getY()).distance(x + velocityX, y + velocityY) < gate ? true : false;
    }

    public double measurementProbability(Measurement measurement) {
        double dist = new Point2D.Double(measurement.getX(), measurement.getY()).distance(x + velocityX, y + velocityY);
        return measurementInGate(measurement) ? (dist < 1 ? 1.0 : 1 / dist) : 0.0;
    }

    public long getId() {
        return id;
    }

    public long getLastDetection() {
        return lastDetection;
    }

    public double getVelocityX() {
        return velocityX;
    }

    public double getVelocityY() {
        return velocityY;
    }

    public double getX() {
        return x;
    }

    public double getY() {
        return y;
    }

    public double[] getBoundingBox() {
        return boundingBox;
    }
}
