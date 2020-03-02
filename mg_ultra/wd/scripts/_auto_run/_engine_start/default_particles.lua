--Some default particle types
Particles.add_new_type("gold", "particle_gold")
Particles.set_bloom_factor("gold", 4.0)
Particles.set_max_life_deviation("gold", 3.0)
Particles.set_featherness("gold", 0.01, 0.001)

Particles.add_new_type("death_gold", "particle_gold")
Particles.set_bloom_factor("gold", 4.0)
Particles.set_max_life_deviation("gold", 3.0)
Particles.set_featherness("gold", 0.05, 0.025)

Particles.add_new_type("death_gold_fragments", "particle_gold_frag")
Particles.set_bloom_factor("death_gold_fragments", 4.0)
Particles.set_max_life_deviation("death_gold_fragments", 3.5)
Particles.set_featherness("death_gold_fragments", 0.012, 0.025)
Particles.set_rotate_to_face("death_gold_fragments", true)
