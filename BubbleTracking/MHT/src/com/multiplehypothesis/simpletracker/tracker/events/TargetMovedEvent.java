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
public class TargetMovedEvent implements Event {

    private static final Logger logger = Logger.getLogger(TargetMovedEvent.class);
    private final long id;
    private final double fromX, fromY, toX, toY;

    public TargetMovedEvent(long id, double fromX, double fromY, double toX, double toY) {
        this.id = id;
        this.fromX = fromX;
        this.fromY = fromY;
        this.toX = toX;
        this.toY = toY;
    }

    public double getFromX() {
        return fromX;
    }

    public double getFromY() {
        return fromY;
    }

    public long getId() {
        return id;
    }

    public double getToX() {
        return toX;
    }

    public double getToY() {
        return toY;
    }
}
