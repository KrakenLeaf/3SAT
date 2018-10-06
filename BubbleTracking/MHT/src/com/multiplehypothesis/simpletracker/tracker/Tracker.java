/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.multiplehypothesis.simpletracker.tracker;

import com.multiplehypothesis.simpletracker.tracker.events.NewTargetEvent;
import com.multiplehypothesis.simpletracker.tracker.events.TargetMovedEvent;
import eu.anorien.mhl.Event;
import eu.anorien.mhl.Fact;
import eu.anorien.mhl.Factory;
import eu.anorien.mhl.HypothesesManager;
import eu.anorien.mhl.Hypothesis;
import eu.anorien.mhl.MHLService;
import eu.anorien.mhl.generator.GeneratedHypotheses;
import eu.anorien.mhl.generator.GeneratedHypothesis;
import eu.anorien.mhl.generator.HypothesesGenerator;
import eu.anorien.mhl.pruner.Pruner;
import eu.anorien.mhl.pruner.PrunerFactory;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.log4j.Logger;
import se.liu.isy.control.assignmentproblem.MurtyAlgorithm;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class Tracker {

    private static final Logger logger = Logger.getLogger(Tracker.class);
    private MHLService service;
    private Factory factory;
    private HypothesesManager hm;
    private SimpleWatcher watcher;
    private long time = 0;
    private long targetIdGen = 0;
    private int maxNumLeaves, maxDepth, timeUndetected, bestK;
    private double probUndetected, probNewTarget, probFalseAlarm;
    private double gateSize;

    public Tracker(
            int maxNumLeaves,
            int maxDepth,
            int timeUndetected,
            int bestK,
            double probUndetected,
            double probNewTarget,
            double probFalseAlarm,
            double gateSize) {
        this.maxNumLeaves = maxNumLeaves;
        this.maxDepth = maxDepth;
        this.timeUndetected = timeUndetected;
        this.bestK = bestK;
        this.probUndetected = probUndetected;
        this.probNewTarget = probNewTarget;
        this.probFalseAlarm = probFalseAlarm;
        this.gateSize = gateSize;

//        ServiceLoader<MHLService> serviceLoader = ServiceLoader.load(MHLService.class);
//        service = serviceLoader.iterator().next();
        service = new eu.anorien.mhl.lisbonimpl.LisbonMHLImpl();
        factory = service.getFactory();
        hm = factory.newHypothesesManager();

        PrunerFactory prunerFactory = factory.getPrunerFactory();

        hm.setPruner(prunerFactory.newCompositePruner(new Pruner[]{
                    prunerFactory.newBestKPruner(maxNumLeaves),
                    prunerFactory.newTreeDepthPruner(maxDepth)}));

        watcher = new SimpleWatcher();
        hm.register(watcher);
    }

    public void newScan(List<Measurement> m) {
        time++;
        Map<Set<Measurement>, Set<Fact>> map = new HashMap<Set<Measurement>, Set<Fact>>();
        Set<Fact> isolatedTargets = new HashSet<Fact>(watcher.getFacts());

        createGroups(m, map, isolatedTargets);

        generateHypForGroups(map);

        generateHypIsolatedTargets(isolatedTargets);
    }

    private void generateHypIsolatedTargets(Set<Fact> isolatedTargets) {
        for (Fact fact : isolatedTargets) {
            HashSet<Fact> reqFacts = new HashSet<Fact>();
            reqFacts.add(fact);
            hm.generateHypotheses(new HypothesesGenerator() {

                public GeneratedHypotheses generate(Set<Event> set, Set<Fact> provFacts) {
                    List<GeneratedHypothesis> generatedHypothesisList = new ArrayList<GeneratedHypothesis>();
                    if (provFacts.isEmpty()) {
                        generatedHypothesisList.add(factory.newGeneratedHypothesis(1, new HashSet<Event>(), new HashSet<Fact>()));
                    } else {
                        HashSet<Fact> newFacts = new HashSet<Fact>();
                        TargetFact target = (TargetFact) provFacts.iterator().next();
                        if (time - target.getLastDetection() <= timeUndetected) {
                            TargetFact targetUpdate = new TargetFact(gateSize, target.getId(), target.getLastDetection(), target.getX() + target.getVelocityX(), target.getY() + target.getVelocityY(), target.getVelocityX(), target.getVelocityY(), target.getBoundingBox());
                            newFacts.add(targetUpdate);
                        }
                        generatedHypothesisList.add(factory.newGeneratedHypothesis(probUndetected, new HashSet<Event>(), newFacts));
                    }
                    return factory.newGeneratedHypotheses(generatedHypothesisList);
                }
            }, new HashSet<Event>(), reqFacts);
        }
    }

    private void generateHypForGroups(Map<Set<Measurement>, Set<Fact>> map) {
        for (final Map.Entry<Set<Measurement>, Set<Fact>> entry : map.entrySet()) {
            hm.generateHypotheses(new HypothesesGenerator() {

                public GeneratedHypotheses generate(Set<Event> set, Set<Fact> provFacts) {
                    List<Measurement> measurements = new ArrayList<Measurement>(entry.getKey());
                    List<Fact> targets = new ArrayList<Fact>(provFacts);
                    double[][] costMatrix = new double[measurements.size()][targets.size() + measurements.size() * 2];
                    for (int i = 0; i < measurements.size(); i++) {
                        Measurement measurement = measurements.get(i);
                        for (int j = 0; j < targets.size(); j++) {
                            costMatrix[i][j] = ((TargetFact) targets.get(j)).measurementProbability(measurement);
                        }
                        costMatrix[i][targets.size() + i] = probFalseAlarm;
                        costMatrix[i][targets.size() + measurements.size() + i] = probNewTarget;
                    }
                    List<GeneratedHypothesis> generatedHypothesesList = new ArrayList<GeneratedHypothesis>();
                    MurtyAlgorithm.MurtyAlgorithmResult result = MurtyAlgorithm.solve(costMatrix, bestK);
                    for (int solution = 0; solution < result.getCustomer2Item().length; solution++) {
                        int[] assignments = result.getCustomer2Item()[solution];
                        double hypProb = 1;
                        Set<Fact> newFacts = new HashSet<Fact>();
                        Set<Event> newEvents = new HashSet<Event>();
                        for (int measurementNumber = 0; measurementNumber < assignments.length; measurementNumber++) {
                            int assignment = assignments[measurementNumber];
                            Measurement measurement = measurements.get(measurementNumber);
                            hypProb *= costMatrix[measurementNumber][assignment];
                            if (assignment < targets.size()) {
                                TargetFact target = (TargetFact) targets.get(assignment);
                                TargetFact targetUpdate = new TargetFact(gateSize, target.getId(), time, measurement.getX(), measurement.getY(), measurement.getX() - target.getX(), measurement.getY() - target.getY(), measurement.getBoundingBoxArray());
                                newFacts.add(targetUpdate);
                                Event e = new TargetMovedEvent(target.getId(), target.getX(), target.getY(), measurement.getX(), measurement.getY());
                                newEvents.add(e);
                            } else if (assignment < targets.size() + measurements.size()) {
                                // False Alarm
                            } else {
                                TargetFact newTarget = new TargetFact(
                                        gateSize,
                                        targetIdGen++,
                                        time, measurement.getX(), measurement.getY(), 0, 0,
                                        measurement.getBoundingBoxArray());
                                newFacts.add(newTarget);
                                Event e = new NewTargetEvent(newTarget.getId(), newTarget.getX(), newTarget.getY());
                                newEvents.add(e);
                            }
                        }
                        int[] item2Customer = result.getItem2Customer()[solution];
                        for (int i = 0; i < targets.size(); i++) {
                            if (item2Customer[i] == -1) {
                                TargetFact target = (TargetFact) targets.get(i);
                                if (time - target.getLastDetection() <= timeUndetected) {
                                    TargetFact targetUpdate = new TargetFact(
                                            gateSize,
                                            target.getId(),
                                            target.getLastDetection(),
                                            target.getX() + target.getVelocityX(),
                                            target.getY() + target.getVelocityY(),
                                            target.getVelocityX(),
                                            target.getVelocityY(),
                                            target.getBoundingBox());
                                    newFacts.add(targetUpdate);
                                }
                                hypProb *= probUndetected;
                            }
                        }
                        generatedHypothesesList.add(factory.newGeneratedHypothesis(hypProb, newEvents, newFacts));
                    }
                    return factory.newGeneratedHypotheses(generatedHypothesesList);
                }
            }, new HashSet<Event>(), entry.getValue());
        }
    }

    private void createGroups(List<Measurement> m, Map<Set<Measurement>, Set<Fact>> map, Set<Fact> isolatedTargets) {
        {
            for (Measurement measurement : m) {
                HashSet<Fact> targets = new HashSet<Fact>();
                HashSet<Measurement> measurements = new HashSet<Measurement>();
                measurements.add(measurement);
                map.put(measurements, targets);
                for (Fact fact : watcher.getFacts()) {
                    TargetFact target = (TargetFact) fact;
                    if (target.measurementInGate(measurement)) {
                        targets.add(fact);
                        isolatedTargets.remove(fact);
                    }
                }
            }
            outter:
            while (true) {
                for (Map.Entry<Set<Measurement>, Set<Fact>> e1 : map.entrySet()) {
                    for (Map.Entry<Set<Measurement>, Set<Fact>> e2 : map.entrySet()) {
                        if (!e1.equals(e2)) {
                            if (interset(e1.getValue(), e2.getValue())) {
                                HashSet<Fact> newFacts = new HashSet<Fact>();
                                newFacts.addAll(e1.getValue());
                                newFacts.addAll(e2.getValue());
                                HashSet<Measurement> newMeasurements = new HashSet<Measurement>();
                                newMeasurements.addAll(e1.getKey());
                                newMeasurements.addAll(e2.getKey());
                                map.put(newMeasurements, newFacts);
                                map.remove(e1.getKey());
                                map.remove(e2.getKey());
                                continue outter;
                            }
                        }
                    }
                }
                break;
            }
        }
    }

    private boolean interset(Set s1, Set s2) {
        for (Object object : s2) {
            if (s1.contains(object)) {
                return true;
            }
        }
        for (Object object : s1) {
            if (s2.contains(object)) {
                return true;
            }
        }
        return false;
    }

    public Hypothesis getBestHypothesis() {
        return hm.getBestHypothesis();
    }
}
