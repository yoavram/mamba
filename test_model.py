# http://docs.python.org/library/unittest.html
import model
import unittest
import scipy

class TestSequenceFunctions(unittest.TestCase):

    def setUp(self):
        self.context = model.Context()
        self.population = model.Population(self.context)

    def test_context(self):
        self.assertIsNotNone(self.context)

    def test_create_population(self):
        pop = model.Population(self.context)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)

        c = model.Context()
        c.founder = "no-founder"
        with self.assertRaises(ValueError):
            model.Population(c)

    def test_mutation(self):
        pop = self.context.mutation(self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)
        for cnt in pop.counts:
            self.assertTrue(cnt>=0)
            
    def test_selection(self):
        pop = self.context.selection(self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)
        

    def test_drift(self, replicates=1000):
        pop = self.context.drift(self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)   

    def test_recombination(self):
        pop = self.context.recombination(self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)

    def test_create_new_allele_method(self):
        new_allele = model.create_new_allele_method(2)
        sum_of_new_alleles = sum([new_allele(0) for _ in range(1000)])
        self.assertEquals(sum_of_new_alleles, 1000)
        sum_of_new_alleles = sum([new_allele(1) for _ in range(1000)])
        self.assertEquals(sum_of_new_alleles, 0)
        
        new_allele = model.create_new_allele_method(3)
        sum_of_new_alleles = sum([new_allele(0) for _ in range(1000)])
        self.assertTrue(sum_of_new_alleles > 1000)
        self.assertTrue(sum_of_new_alleles < 2000)
        sum_of_new_alleles = sum([new_allele(2) for _ in range(1000)])
        self.assertTrue(sum_of_new_alleles > 100)
        self.assertTrue(sum_of_new_alleles < 900)

    def test_add_new_class(self):
        genome = self.population.genomes[0].copy()
        genome[0] = (genome[0]+1)%2
        length_before = len(self.population.counts)

        self.context.add_new_class(self.population, genome)

        self.assertEquals(length_before+1, len(self.population.counts))
        self.assertEquals(length_before+1, len(self.population.fitness))
        self.assertEquals(length_before+1, len(self.population.mutation_rates))
        self.assertEquals(length_before+1, len(self.population.recombination_rates))
        self.assertEquals(length_before+1, len(self.population.genomes))
        self.assertTrue(genome.tostring() in self.population.revmap)
        key = self.population.revmap[genome.tostring()]
        genome2 = self.population.genomes[key]
        self.assertTrue( (genome==genome2).all() )
        
    def test_remove_empty_class(self):
        length_before = len(self.population.counts)
        genome_before = self.population.genomes[0]
        
        self.context.remove_empty_class(self.population, 0)

        self.assertEquals(length_before, len(self.population.counts)+1)
        self.assertEquals(length_before, len(self.population.fitness)+1)
        self.assertEquals(length_before, len(self.population.mutation_rates)+1)
        self.assertEquals(length_before, len(self.population.recombination_rates)+1)
        self.assertEquals(length_before, len(self.population.genomes)+1)
        self.assertFalse(genome_before.tostring() in self.population.revmap)

    def test_new_allele_by_recombination(self):
        locus = 0
        allele = self.context.new_allele_by_recombination(self.population, locus)
        self.assertEquals(allele, 0)

        new_genome = self.population.genomes[0].copy()
        new_genome[0] = 1
        self.context.add_new_class(self.population, new_genome)
        allele = self.context.new_allele_by_recombination(self.population, locus)
        self.assertEquals(allele, 0)

        
    def tearDown(self):
        pass

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestSequenceFunctions)
    unittest.TextTestRunner(verbosity=2).run(suite)
    #unittest.main()
