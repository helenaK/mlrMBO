context("multicrit: mspot")

test_that("multicrit mspot works", {

  # Test normal run
  learner = makeLearner("regr.km", nugget.estim = TRUE, predict.type = "se")
  ctrl = makeMBOControl(n.objectives = 2L)
  ctrl = setMBOControlTermination(ctrl, iters = 5L)
  ctrl = setMBOControlInfill(ctrl, crit = "ei", opt = "nsga2", opt.nsga2.generations = 1L, opt.nsga2.popsize = 12L)
  ctrl = setMBOControlMultiCrit(ctrl, method = "mspot")
  or = mbo(testf.zdt1.2d, testd.zdt1.2d, learner = learner, control = ctrl)
  op = as.data.frame(or$opt.path)
  k = seq_row(testd.zdt1.2d)
  expect_true(all(is.na(op$ei.y_1[k])))
  expect_true(all(is.na(op$ei.y_2[k])))
  expect_true(all(!is.na(op$ei.y_1[-k])))
  expect_true(all(!is.na(op$ei.y_2[-k])))
  expect_true(!any(is.na(or$pareto.front)))
})
