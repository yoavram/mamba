import model
import unittest
import scipy

class TestSequenceFunctions(unittest.TestCase):

    def setUp(self):
        self.context = model.create_context()

    def test_context(self):
        self.assertIsNotNone(self.context)

    def test_create_population(self):
        pop = model.create_population(self.context)
        self.assertIsNotNone(pop)
        self.assertNotEquals(len(pop), 0)

        c = model.Context()
        c.founder = "no-founder"
        with self.assertRaises(ValueError):
            model.create_population(c)
        

    def test_mutation(self):
        pass

    def test_selection(self):
        pass

    def test_drift(self, replicates=1000):
        pop = model.create_population(self.context)        
        pop_next = model.drift(self.context, pop) 

        self.assertNotNone(pop2)
        self.assertEquals(len(pop), len(pop2))
        self.assertEquals(sum(pop), sum(pop2))
        for i in pop2:
            self.assert(i>=0)      

    def test_recombination(self):
        pass


    def tearDown(self):
        pass

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestSequenceFunctions)
    unittest.TextTestRunner(verbosity=2).run(suite)
    #unittest.main()
