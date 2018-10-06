/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker.tracker;

import org.apache.log4j.Logger;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class Measurement {

    private static final Logger logger = Logger.getLogger(Measurement.class);
    private double x, y;
    private double boundingBoxTopX, boundingBoxTopY, boundingBoxTopWidth, boundingBoxTopHeight;

    public Measurement(double boundingBoxTopX, double boundingBoxTopY, double boundingBoxTopWidth, double boundingBoxTopHeight) {
        this.x = boundingBoxTopX + boundingBoxTopWidth / 2;
        this.y = boundingBoxTopY - boundingBoxTopHeight / 2;
        this.boundingBoxTopX = boundingBoxTopX;
        this.boundingBoxTopY = boundingBoxTopY;
        this.boundingBoxTopWidth = boundingBoxTopWidth;
        this.boundingBoxTopHeight = boundingBoxTopHeight;
    }

    public double getBoundingBoxTopHeight() {
        return boundingBoxTopHeight;
    }

    public double getBoundingBoxTopWidth() {
        return boundingBoxTopWidth;
    }

    public double getBoundingBoxTopX() {
        return boundingBoxTopX;
    }

    public double getBoundingBoxTopY() {
        return boundingBoxTopY;
    }

    public double getX() {
        return x;
    }

    public double getY() {
        return y;
    }

    public double[] getBoundingBoxArray() {
        return new double[] {boundingBoxTopX, boundingBoxTopY, boundingBoxTopWidth, boundingBoxTopHeight};
    }
}
