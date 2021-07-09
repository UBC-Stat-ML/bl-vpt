# State as of April 16

Good progress on the project, would probably be enough for a paper, but to make it a fully practical method will need a bit more work.

Key limitations as of now:

## Why convergence sometimes fail / is very slow?

### Example: VariationalHierar-auto

```/Users/bouchard/w/ptanalysis/results/all/2021-04-15-20-34-19-D3chDtfd.exec```

```
--model.interpolation.target.filter Ariane
--engine.nScansPerGradient 5
--engine.optimizer Adam
--engine.optimizer.stepScale 0.1
--engine.optimizer.schedule Polynomial
--engine.pt.nChains 50
--engine.pt.nPassesPerScan 0.1
--engine.pt.nScans 400
```


Replicating in ``2021-04-16-09-55-09-XW3DWg0h.exec``: looks like performance eventually improves but very slowly. 

Increased ``--engine.nScansPerGradient 10`` still goes slow (but a bit better)

In ``2021-04-16-10-25-14-57qScaYw.exec`` Increased ``--engine.nScansPerGradient 20`` still slow.

Maybe it's the learning rate!

``2021-04-16-10-27-54-3sbbk2R9.exec`` Gradient 10, learning rate 1: ah! faster! GOOD ONE

``2021-04-16-10-34-37-WYBxPFPy.exec`` Gradient 10, step size 2, **an interesting one**. First crashes then recovers. With 1000 iteration: ``/Users/bouchard/w/ptanalysis/results/all/2021-04-16-10-38-52-az1LNB6w.exec``


Gradient 50, step 2 ``2021-04-16-11-38-04-FsXcrOcJ.exec``  - worse

### Example: non-collapsed

```2021-04-16-13-31-43-yFH0YptU.exec``` : works well, but shows changes of direction needed

``2021-04-16-13-34-25-S682Euw4.exec`` increased step size to 1, makes things less nice

``2021-04-16-13-36-48-VbrDOryh.exec`` this time things explode at the end

This thing is not super nice to explore.

More gradient steps:

ADAM: ``2021-04-16-13-39-02-9Is6XKoy.exec`` reveals some oscillatory behaviour

switching to SGD ``2021-04-16-13-45-53-jE12VXTr.exec`` - less oscillatory, running even longer in ``2021-04-16-13-49-01-zeQA32P1.exec``

### Hypotheses

1. Need to take a turn early on, too big of a step size takes you in another bassin


### Confirmatory experiments

- Can we replicate this behaviour in the collapsed model? 

### Remedies

- Consider better initialization. Moment match posterior!!!
    - pretty powerful ``2021-04-16-14-57-15-cA8RJnIY.exec``
        - naive GCD ~ 2.3 ``2021-04-17-06-39-24-aLRAl4r2.exec``
        - with this init ~ 0.3
        - close to 10x improvement
    - have a call with Vittorio
    - what are the uses of optimization then?
        - factorized target each with their mini-spline?
        - for multimodal stuff, opt might do something more interesting.. - check with ODE or mixture?
        - for fat tail models [!!!], better use t-distributed variational distribution; then can still use moment matching as init, but opt will do something non-trivial. 
- Line search trick?


# PTBM (PT Base Measure Optimization)

See commits on Apr 22

- results around ``2021-04-22-23-47-34-fQ1poJq2.exec`` and before recapitulate the decrease for the collapsed hierarchical example

- results in ``2021-04-23-12-02-14-YdGXXTm5.exec`` (with vari) and ``2021-04-23-12-06-47-QsIuNK9H.exec`` show a more modest decrease in Lambda (roughly from 5.6 to 5.0) but crucially the variational version does still capture the multimodality