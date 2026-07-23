import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";

const PHASES = [
  { text: "Ω", subtitle: "", duration: 1200 },
  { text: "OMEGA", subtitle: "Initializing Neural Core...", duration: 1400 },
  { text: "OMEGA", subtitle: "Loading Context Memory...", duration: 1000 },
  { text: "OMEGA", subtitle: "Calibrating Reasoning Engine...", duration: 1000 },
  { text: "OMEGA", subtitle: "Connecting Knowledge Graph...", duration: 1000 },
  { text: "OMEGA", subtitle: "Systems Online. Ready.", duration: 1200 },
];

export default function OmegaIntro({ onComplete }) {
  const [phase, setPhase] = useState(0);
  const [particles, setParticles] = useState([]);

  useEffect(() => {
    const pts = Array.from({ length: 40 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      size: Math.random() * 3 + 1,
      delay: Math.random() * 2,
    }));
    setParticles(pts);
  }, []);

  useEffect(() => {
    if (phase < PHASES.length - 1) {
      const timer = setTimeout(() => setPhase(phase + 1), PHASES[phase].duration);
      return () => clearTimeout(timer);
    } else {
      const timer = setTimeout(() => onComplete(), 1500);
      return () => clearTimeout(timer);
    }
  }, [phase, onComplete]);

  return (
    <motion.div
      className="fixed inset-0 z-50 bg-black flex items-center justify-center overflow-hidden"
      exit={{ opacity: 0 }}
      transition={{ duration: 0.8 }}
    >
      {/* Particle field */}
      {particles.map((p) => (
        <motion.div
          key={p.id}
          className="absolute rounded-full bg-teal-400"
          style={{ width: p.size, height: p.size, left: `${p.x}%`, top: `${p.y}%` }}
          animate={{
            opacity: [0, 0.8, 0],
            scale: [0.5, 1.5, 0.5],
          }}
          transition={{
            duration: 3,
            delay: p.delay,
            repeat: Infinity,
            ease: "easeInOut",
          }}
        />
      ))}

      {/* Pulsing ring */}
      <motion.div
        className="absolute w-64 h-64 rounded-full border border-teal-500/30"
        animate={{
          scale: [1, 1.5, 1],
          opacity: [0.3, 0.1, 0.3],
        }}
        transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
      />
      <motion.div
        className="absolute w-48 h-48 rounded-full border border-teal-400/20"
        animate={{
          scale: [1.2, 0.8, 1.2],
          opacity: [0.2, 0.4, 0.2],
        }}
        transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}
      />

      <div className="relative z-10 text-center">
        <AnimatePresence mode="wait">
          <motion.div
            key={phase}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.5 }}
          >
            <h1
              className={`font-display font-black tracking-wider text-white ${
                phase === 0 ? "text-8xl" : "text-5xl"
              }`}
            >
              {PHASES[phase].text}
            </h1>
            {PHASES[phase].subtitle && (
              <motion.p
                className="mt-4 text-teal-400 text-sm tracking-[0.3em] uppercase font-mono"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.3 }}
              >
                {PHASES[phase].subtitle}
              </motion.p>
            )}
          </motion.div>
        </AnimatePresence>

        {/* Progress bar */}
        <div className="mt-10 w-64 mx-auto h-px bg-white/10 rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-teal-400"
            animate={{ width: `${((phase + 1) / PHASES.length) * 100}%` }}
            transition={{ duration: 0.5 }}
          />
        </div>

        <motion.p
          className="mt-6 text-white/30 text-xs tracking-widest uppercase"
          animate={{ opacity: [0.3, 0.7, 0.3] }}
          transition={{ duration: 2, repeat: Infinity }}
        >
          Created by Thomas Lee Harvey
        </motion.p>
      </div>
    </motion.div>
  );
}