/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker;

import static java.lang.Math.*;
import org.apache.log4j.Logger;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class Target {

    private static final Logger logger = Logger.getLogger(Target.class);
    private double x, y, heading, velocity;

    public Target() {
        x = random() * 400;
        y = random() * 400;
        heading = random() * 2 * PI;
        velocity = random() * 5;
    }

    public void update() {
        heading = (random() - 0.5) + heading;
        velocity = min(5, max(0, velocity + random()));
        x = min(390, max(10, x + velocity * cos(heading)));
        y = min(390, max(10, y + velocity * sin(heading)));
    }

    public double getX() {
        return x;
    }

    public double getY() {
        return y;
    }
}
