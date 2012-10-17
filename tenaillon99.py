'''
Created on 18/03/2012

Code available on https://bitbucket.org/yoavram/pysimba

Implements the model from:
Tenaillon O, Toupance B, Nagard H Le, Taddei F, Godelle B (1999)
Mutators, Population Size, Adaptive Landscape and the Adaptation of Asexual Populations of Bacteria.
Genetics 152:485-493.
Available at: http://www.genetics.org/cgi/content/abstract/152/2/485 

Differences from original:
* Population growth is modeled by multiplying the number of individuals drawn in the drift phase rather than through the selection phase,
 as I don't understand how it was done.
* The mutation matrix is not the same as the original is missing information on how it was done. 
* Adaptation time is set when the fraction of adapted individuals is 0.99, not sure why they used 1-1e-9. In Tenaillon et al. 2000 it is 0.95.

author: yoavram@post.tau.ac.il
'''
import numpy 
import time
import ConfigParser
import pymongo

POP_SIZE_TH = 1e9
INTERVAL = 100

def make_opt_parser():
    import optparse
    parser = optparse.OptionParser(prog='python tenaillon99.py')
    #parser.add_option('--pp',metavar='use parallel python ',action="store_true", default=False, help='default is False')
    parser.add_option('--r',metavar='# of replicates ',type='int', default=1, help='integer > 0')
    parser.add_option('--D',metavar='# of deleterious alleles ',type='int', default=20, help='integer > 0')
    parser.add_option('--B',metavar='# of beneficial alleles ',type='int', default=2, help='integer > 0')
    parser.add_option('--P',metavar='max population size', type='long', default=1e9, help='integer > 0')
    parser.add_option('--SB',metavar='selection advantage of beneficial alleles',type='float',  default=0.03, help='0<s<1')
    parser.add_option('--SD',metavar='selection disadvantage of deleterious alleles',type='float',  default=0.01, help='0<s<1')    
    parser.add_option('--UL',metavar='mutation rate: lethals',type='float',  default=1e-5, help='per site per generation, 0<UL<1')
    parser.add_option('--UD',metavar='mutation rate: deleterious',type='float',  default=1e-4, help='per site per generation, 0<UD<1')
    parser.add_option('--UB',metavar='mutation rate: beneficials',type='float',  default=1e-8, help='per site per generation, 0<UB<1')        
    parser.add_option('--UM',metavar='mutation rate: mutators',type='float',  default=5e-7, help='per site per generation, 0<UB<1')
    parser.add_option('--UN',metavar='mutation rate: non-mutators',type='float',  default=5e-10, help='per site per generation, 0<UB<1')    
    parser.add_option('--m',metavar='mutator strength',type='float',  default=1.0, help='m > 0')
    parser.add_option('--a',metavar='adaptation threshold',type='float',  default=0.95, help='frequency of population with all adaptations required to stop the simulation, 0<a<1')
    parser.add_option('--c',metavar='configuration filename',type='string',  default='tenaillon.properties', help='parsed using ConfigParser', dest='cfg_filename')
    return parser 


def make_args():
    parser = make_opt_parser()
    import sys
    if sys.argv[0] != 'tenaillon99.py':
        return parser.parse_args([])[0]
    else:
        return parser.parse_args()[0]
    
def make_w_mat(args):
    w = []
    for b in range(args.B+1):
        for d in range(args.D+1):
            w.append(1+b*args.SB-d*args.SD)
    w = numpy.array(numpy.diag(w+w),dtype=numpy.float64)
    return w

def make_m_mat(args):
    size = (args.B+1)*(args.D+1)
    m = numpy.zeros((size*2,size*2),dtype=numpy.float64)
    # m[i,j] is the probability to mutate from j to i
    for i in range(size):
        di = i%(args.D+1)
        bi = i/(args.D+1)
        for j in range(size):
            if j!= i: 
                mod = 1.0
                if j > size:
                    mod = args.m # this affects only the mutator frequencies          
                dj = j%(args.D+1)
                bj = j/(args.D+1)                                
                # one beneficial and or one deleterious mutation per generation
                if (abs(dj-di)+abs(bj-bi) == 1):
                    m[i,j] = 1.0
                    if dj == di+1:
                        m[i,j] *= args.UB*mod
                    elif dj == di-1:
                        m[i,j] *= args.UD*mod
                    elif bj == bi+1:
                        m[i,j] *= args.UD*mod
                    elif bj == bi-1:
                        m[i,j] *= args.UB*mod    
    for i in range(size*2):
        m[i,i] = 1.0-numpy.sum([m[j,i] for j in range(size) if j != i])  
        
    for i in range(size):
        m[i,i+size] = args.UN
        m[i+size,i] = args.UM*args.m  # this affects only the mutator frequencies           
    return m

def poisson(n,th=100):
    for i,k in enumerate(n):
        if k < th:
            n[i]=numpy.random.poisson(k)

def f_selection(args,f):
    f = args.w_mat.dot(f)
    f = f/f.sum()
    return f

def n_selection(args,n):
    n = args.w_mat.dot(n)
    pop_size = n.sum()    
    if pop_size < 1e5:
        f = n/pop_size
        n = numpy.random.multinomial(pop_size, f).astype(numpy.uint64)
    else:
        poisson(n)    
    return n

def f_mutation(args,f):
    # TODO lethals
    f = args.m_mat.dot(f)
    return f 

def n_mutation(args,n):
    # TODO lethals
    n1 = args.m_mat.dot(n)
    poisson(n1)
    while n1.sum()==0:
        n1 = args.m_mat.dot(n)
        poisson(n1)
    return n1

def f_drift(args,f):    
    n = args.P*f
    poisson(n)
    f = n/numpy.float64(n.sum())
    return f

def n_drift(args,n,pop_increase=1):
    if pop_increase != 1:
        n = pop_increase*n
    pop_size = n.sum()
    if pop_size < 1e5:
        f = n/numpy.float64(pop_size)
        n = numpy.random.multinomial(pop_size, f).astype(numpy.uint64)
    else:
        poisson(n)
    return n

def fraction_of_adapted(args,n):
    size = (args.B+1)*(args.D+1)
    x = n[size-(args.D+1):size].sum()+n[2*size-(args.D+1):2*size].sum()
    if x >= 1:
        x /= numpy.float64(n.sum())
    return x 

def fraction_of_mutators(args,n):
    size = (args.B+1)*(args.D+1)
    x = n[size:2*size].sum()
    if x >= 1:
        x /= numpy.float64(n.sum())
    return x 

def save_data(data):
    host = config.get('pymongo','host')
    db = config.get('pymongo','db')
    col = config.get('pymongo','collection')
    conn = pymongo.Connection(host)
    collection = conn[db][col]
    return collection.save(data)
    
def sparse_array(arr):
    for i in range(1,len(arr)+1):
        if arr[-i]>0: break
    return arr[:-i+2]

def compress_data(data):
    data['f'] = [ sparse_array(data['f'][i]) for i in range(len(data['f'])) ]
    
def simulation(args):
    size = (args.B+1)*(args.D+1)        
    n0 = numpy.zeros(size*2, dtype=numpy.uint64)
    n0[0] = 1
    data = {'timestamp':time.asctime(), 'P':args.P,'B':args.B,'D':args.D,'SB':args.SB,'SD':args.SD,'UL':args.UL,'UD':args.UD,'UB':args.UB,'UM':args.UM,'UN':args.UN,'m':args.m,'a':args.a,'f':[]}
    print 'Starting with arguments:',args
    # simulation
    if args.P < POP_SIZE_TH:
        # density based 
        print 'Starting density-based model (Tenaillon et al. 1999)'
        gen = 0
        adapted = 0       
        n = n0
        pop_size = n.sum()
        # get to population capacity
        while pop_size < args.P:
            gen += 1
            #print '0',type(n[0])
            n = n_selection(args,n)
            #print '1',type(n[0])
            n = n_mutation(args,n)
            #print '2',type(n[0])
            n = n_drift(args,n,2)
            #print '3',type(n[0])
            pop_size = n.sum()
            data['f'].append(n.tolist())           
            if gen%INTERVAL==0:                
                print "Generation",gen,"Population Size",pop_size                
        # wait for adaptation
        while adapted < args.a:            
            gen += 1
            n = n_selection(args,n)
            n = n_mutation(args,n)
            n = n_drift(args,n)
            adapted = fraction_of_adapted(args,n)            
            data['f'].append(n.tolist())            
            if gen%INTERVAL==0:
                print "Generation",gen,"Adapted",adapted,"Mutators",fraction_of_mutators(args, n)
        data['W'] = args.w_mat.diagonal().dot(n/numpy.float64(pop_size))
        data['mutators'] = fraction_of_mutators(args, n)
    else:
        # frequency based
        print 'Starting frequency-based model (Tenaillon et al. 1999)'
        gen = 0
        adapted = 0
        n = n0                
        pop_size = 1.0
        
        # get to population capacity
        while pop_size < args.P:
            gen += 1            
            n = n_selection(args,n)
            n = n_mutation(args,n)
            n = n_drift(args,n,2) 
            pop_size = n.sum()
            data['f'].append((n/numpy.float64(pop_size)).tolist())            
            if gen%INTERVAL==0:
                print "Generation",gen,"Population Size",pop_size  
        f = n/numpy.float64(n.sum())
        print "Changing to frequency-dependent"
        # wait for adaptation
        while adapted < args.a:
            gen += 1
            f = f_selection(args,f)
            f = f_mutation(args,f)            
            f = f_drift(args,f)           
            adapted = fraction_of_adapted(args,f)
            data['f'].append(f.tolist())
            if gen%INTERVAL==0: 
                print "Generation",gen,"Adapted",adapted,"Mutators",fraction_of_mutators(args, f)
        data['W'] = args.w_mat.diagonal().dot(f)
        data['mutators'] = fraction_of_mutators(args, f)
    data['adaptation_time'] = gen    
    print "Finished, adaptation time",gen,"generations","Mean fitness",data['W'],'Mutator fraction',data['mutators']
    return data

def run(args):
    for _ in range(args.r):
        data = simulation(args)
        compress_data(data)
        print 'Saved to DB:',save_data(data)    

if __name__ == '__main__':
    parser = make_opt_parser()
    args = parser.parse_args()[0]
    config = ConfigParser.ConfigParser()
    config.read(args.cfg_filename)
    args.m_mat = make_m_mat(args)
    args.w_mat = make_w_mat(args) 
    run(args)
