# http://docs.python.org/library/unittest.html
import model
import unittest
import scipy

class TestSequenceFunctions(unittest.TestCase):

    def setUp(self):
        self.context = model.create_context()
        self.population = model.create_population(self.context)

    def test_context(self):
        self.assertIsNotNone(self.context)

    def test_create_population(self):
        pop = model.create_population(self.context)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)

        c = model.create_context()
        c.founder = "no-founder"
        with self.assertRaises(ValueError):
            model.create_population(c)

    def test_mutation(self):
        pop = model.mutation(self.context, self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)
        for cnt in pop.counts:
            self.assertTrue(cnt>=0)
            
    def test_selection(self):
        pop = model.selection(self.context, self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)
        

    def test_drift(self, replicates=1000):
        pop = model.drift(self.context, self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)   

    def test_recombination(self):
        pop = model.recombination(self.context, self.population)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop.counts), 0)
        size = sum(pop.counts)
        self.assertEquals(size, pop.size)

    def tearDown(self):
        pass

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestSequenceFunctions)
    unittest.TextTestRunner(verbosity=2).run(suite)
    #unittest.main()
