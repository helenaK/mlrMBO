##### optimizing a simple noisy sin(x) with mbo / EI

library(mlrMBO)
library(ggplot2)
library(smoof)
set.seed(1)
configureMlr(show.learner.output = FALSE)
pause = interactive()


# function with noise
# for 2 mf levels
obj.fun = makeSingleObjectiveFunction(
  name = "Multifidelity function",
  fn = function(x) {
    if (is.null(x$.multifid.lvl)) x$multifid.lvl = 2
    sin(x$x) + rnorm(1, 0, 0.1) - (x$.multifid.lvl - 2) * (0.05 * (x$x - 7)^2 + 1)
  },
  par.set = makeNumericParamSet(lower = 3, upper = 13, len = 1L),
  has.simple.signature = FALSE,
  noisy = TRUE,
  global.opt.value = -1
)

# here in this example we know the true, deterministic function
obj.fun.mean = function(x) {
  if (is.null(x$.multifid.lvl))
    x$multifid.lvl = 2
  sin(x$x) - (x$.multifid.lvl - 2)*(0.05*(x$x-7)^2 + 1)
}

ctrl = makeMBOControl(
  propose.points = 1L,
  final.method = "best.predicted",
  final.evals = 10L
)
ctrl = setMBOControlTermination(ctrl, iters = 5L)


lrn = makeLearner("regr.km", predict.type = "se", nugget.estim = TRUE)

ctrl = setMBOControlInfill(ctrl, crit = "ei", opt = "focussearch",
  opt.focussearch.points = 500L)
ctrl = setMBOControlMultiFid(ctrl, lvls = c(0.1, 1), costs = c(1, 4), param = "p")

design = generateDesign(10L, getParamSet(obj.fun), fun = lhs::maximinLHS)

run = exampleRun(obj.fun, design = design, learner = lrn,
  control = ctrl, points.per.dim = 200L, noisy.evals = 50L, fun.mean = obj.fun.mean,
  show.info = TRUE)

print(run)

res = plotExampleRun(run, pause = pause, densregion = TRUE)
