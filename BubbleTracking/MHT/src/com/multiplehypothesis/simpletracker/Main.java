package com.multiplehypothesis.simpletracker;

import eu.anorien.mhl.Fact;
import java.awt.Color;
import java.awt.EventQueue;
import java.awt.Graphics;
import java.awt.geom.Point2D;
import java.lang.reflect.InvocationTargetException;
import java.util.ArrayList;
import java.util.List;
import javax.swing.JFrame;
import com.multiplehypothesis.simpletracker.tracker.TargetFact;
import com.multiplehypothesis.simpletracker.tracker.Tracker;

/**
 *
 * @author David Miguel Antunes <davidmiguel [ at ] antunes.net>
 */
public class Main {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws InterruptedException, InvocationTargetException {
        final Object lock = new Object();
        final Tracker tracker = new Tracker(7, 6, 6, 2, 10, 0.001, 0.01, 0.1);
        final List<Target> targets = new ArrayList<Target>();
        for (int i = 0; i < 20; i++) {
            targets.add(new Target());
        }
        final List<Point2D> noiseMeasurements = new ArrayList<Point2D>();
        final List<Point2D> correctMeasurements = new ArrayList<Point2D>();

        final JFrame groundTruthFrame = new JFrame("Ground truth") {

            @Override
            public void paint(Graphics g) {
                synchronized (lock) {
                    g.clearRect(0, 0, 400, 400);
                    for (Target target : targets) {
                        g.fillOval((int) target.getX() - 2, (int) target.getY() - 2, 4, 4);
                    }
                }
            }
        };
        groundTruthFrame.setSize(400, 400);
        groundTruthFrame.setResizable(false);
        groundTruthFrame.setVisible(true);
        groundTruthFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        final JFrame measurementsFrame = new JFrame("Measurements") {

            @Override
            public void paint(Graphics g) {
                synchronized (lock) {
                    g.clearRect(0, 0, 400, 400);
                    g.setColor(Color.red);
                    for (Point2D point2D : noiseMeasurements) {
                        g.fillOval((int) point2D.getX() - 2, (int) point2D.getY() - 2, 4, 4);
                    }
                    g.setColor(Color.green);
                    for (Point2D point2D : correctMeasurements) {
                        g.fillOval((int) point2D.getX() - 2, (int) point2D.getY() - 2, 4, 4);
                    }
                }
            }
        };
        measurementsFrame.setSize(400, 400);
        measurementsFrame.setResizable(false);
        measurementsFrame.setVisible(true);
        measurementsFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        final JFrame trackerFrame = new JFrame("Tracker") {

            @Override
            public void paint(Graphics g) {
                synchronized (lock) {
                    g.clearRect(0, 0, 400, 400);
                    g.setColor(Color.red);
                    for (Fact fact : tracker.getBestHypothesis().getFacts().keySet()) {
                        TargetFact target = (TargetFact) fact;
                        g.fillRect((int) target.getX() - 4, (int) target.getY() - 4, 4, 8);
                    }
                    g.setColor(Color.green);
                    for (Target target : targets) {
                        g.fillOval((int) target.getX(), (int) target.getY() - 4, 4, 8);
                    }
                }
            }
        };
        trackerFrame.setSize(400, 400);
        trackerFrame.setResizable(false);
        trackerFrame.setVisible(true);
        trackerFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        while (true) {
            synchronized (lock) {
                for (Target target : targets) {
                    target.update();
                }
                noiseMeasurements.clear();
                correctMeasurements.clear();
                for (int i = 0; i < 80; i++) {
                    noiseMeasurements.add(new Point2D.Double(Math.random() * 400, Math.random() * 400));
                }
                for (Target target : targets) {
                    if (Math.random() < 0.95) {
                        correctMeasurements.add(new Point2D.Double(target.getX(), target.getY()));
                    }
                }
                List<Point2D> finalMeasurements = new ArrayList<Point2D>();
                finalMeasurements.addAll(noiseMeasurements);
                finalMeasurements.addAll(correctMeasurements);
//                tracker.newScan(finalMeasurements);
            }

            EventQueue.invokeAndWait(new Runnable() {

                public void run() {
                    groundTruthFrame.repaint();
                    measurementsFrame.repaint();
                    trackerFrame.repaint();
                }
            });

            Thread.sleep(100);
        }

    }
}
