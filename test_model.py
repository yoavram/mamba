# http://docs.python.org/library/unittest.html
import model
import unittest
import scipy

class TestSequenceFunctions(unittest.TestCase):

    def setUp(self):
        self.context = model.Context()
        self.population = model.create_population(self.context)

    def test_context(self):
        self.assertIsNotNone(self.context)

    def test_create_population(self):
        pop = model.create_population(self.context)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)

        c = model.Context()
        c.founder = "no-founder"
        with self.assertRaises(ValueError):
            model.create_population(c)

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
        
        
    def tearDown(self):
        pass

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestSequenceFunctions)
    unittest.TextTestRunner(verbosity=2).run(suite)
    #unittest.main()
