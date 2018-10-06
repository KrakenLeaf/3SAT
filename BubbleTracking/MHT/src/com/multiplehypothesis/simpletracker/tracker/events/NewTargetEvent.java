/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker.tracker.events;

import eu.anorien.mhl.Event;
import org.apache.log4j.Logger;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class NewTargetEvent implements Event {

    private static final Logger logger = Logger.getLogger(NewTargetEvent.class);
    private final long id;
    private final double x, y;

    public NewTargetEvent(long id, double x, double y) {
        this.id = id;
        this.x = x;
        this.y = y;
    }

    public long getId() {
        return id;
    }

    public double getX() {
        return x;
    }

    public double getY() {
        return y;
    }
}
