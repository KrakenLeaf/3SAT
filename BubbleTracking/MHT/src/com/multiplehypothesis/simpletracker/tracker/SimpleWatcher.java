/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker.tracker;

import eu.anorien.mhl.Event;
import eu.anorien.mhl.Fact;
import eu.anorien.mhl.Hypothesis;
import eu.anorien.mhl.Watcher;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import org.apache.log4j.Logger;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class SimpleWatcher implements Watcher {

    private static final Logger logger = Logger.getLogger(SimpleWatcher.class);
    private Set<Fact> facts = new HashSet<Fact>();

    public void newFact(Fact fact) {
        facts.add(fact);
    }

    public void newFacts(Collection<Fact> clctn) {
        for (Fact fact : clctn) {
            newFact(fact);
        }
    }

    public void removedFact(Fact fact) {
        facts.remove(fact);
    }

    public void removedFacts(Collection<Fact> clctn) {
        for (Fact fact : clctn) {
            removedFact(fact);
        }
    }

    public void newEvent(Event event) {
    }

    public void newEvents(Collection<Event> clctn) {
    }

    public void removedEvent(Event event) {
    }

    public void removedEvents(Collection<Event> clctn) {
    }

    public void confirmedEvent(Event event) {
    }

    public void confirmedEvents(Collection<Event> clctn) {
    }

    public void bestHypothesis(Hypothesis hpths) {
    }

    public Set<Fact> getFacts() {
        return facts;
    }
}
