#' @title Set termination options.
#'
#' @description
#' Extends an MBO control object with infill criteria and infill optimizer options.
#'
#' @template arg_control
#' @param iters [\code{integer(1)}]\cr
#'   Number of sequential optimization steps.
#'   Default is 10.
#' @param time.budget [\code{integer(1)} | NULL]\cr
#'   Running time budget in seconds. Note that the actual mbo run can take more time since
#'   the condition is checked after each iteration.
#'   The default \code{NULL} means: There is no time budget.
#' @param exec.time.budget [\code{integer(1)} | NULL]\cr
#'   Execution time (time spent executing the function passed to \code{mbo})
#'   budget in seconds. Note that the actual mbo run can take more time since
#'   the condition is checked after each iteration.
#'   The default \code{NULL} means: There is no execution time budget.
#' @param target.fun.value [\code{numeric(1)}] | NULL]\cr
#'   Stopping criterion for single crit optimization: Stop if a function evaluation
#'   is better than this given target.value.
#'   The default \code{NULL} means: The function value won't be taken into account for stopping.
#' @param max.evals [\code{integer(1) | NULL}]\cr
#'   Maximal number of function evaluations.
#'   The default \code{NULL} means: The total number of evaluations won't be taken into account for stopping.
#' @param more.stop.conds [\code{list}]\cr
#'   Optional list of termination conditions. Each condition needs to be a function
#'   of a single argument \code{opt.state} of type \code{\link{OptState}} and should
#'   return a list with the following elements:
#'   \describe{
#'     \item{term [\code{logical(1)}]}{Logical value indicating whether the
#'     stopping condition is met.}
#'     \item{message [\code{character(1)}]}{Stopping message.}
#'   }
#' @return [\code{\link{MBOControl}}].
#' @examples
#' fn = smoof::makeSphereFunction(1L)
#' ctrl = makeMBOControl()
#'
#' # custom stopping condition (stop if target function value reached)
#' # We neglect the optimization direction (min/max) in this example.
#' yTargetValueTerminator = function(y.val) {
#'   force(y.val)
#'   function(opt.state) {
#'     opt.path = opt.state$opt.path
#'     current.best = getOptPathEl(opt.path, getOptPathBestIndex((opt.path)))$y
#'     term = (current.best <= y.val)
#'     message = if (!term) NA_character_ else sprintf("Target function value %f reached.", y.val)
#'     return(list(term = term, message = message))
#'   }
#' }
#'
#' # assign custom stopping condition
#' ctrl = setMBOControlTermination(ctrl, more.stop.conds = list(yTargetValueTerminator(0.05)))
#' res = mbo(fn, control = ctrl)
#' @family MBOControl
#' @export
setMBOControlTermination = function(control,
  iters = 10L, time.budget = NULL, exec.time.budget = NULL, target.fun.value = NULL, max.evals = NULL, more.stop.conds = list()) {

  assertList(more.stop.conds)

  stop.conds = more.stop.conds

  if (is.null(iters) && is.null(time.budget) && is.null(exec.time.budget) && length(stop.conds) == 0L) {
    stopf("You need to specify a maximal number of iteration, a time budget or at least
      one custom stopping condition, but you provided neither.")
  }

  if (!is.null(iters)) {
    stop.conds = c(stop.conds, makeMBOTerminationMaxIter(iters))
  }

  if (!is.null(time.budget)) {
    stop.conds = c(stop.conds, makeMBOTerminationMaxBudget(time.budget))
  }

  if (!is.null(exec.time.budget)) {
    stop.conds = c(stop.conds, makeMBOTerminationMaxExecBudget(exec.time.budget))
  }

  if (!is.null(max.evals)) {
    stop.conds = c(stop.conds, makeMBOTerminationMaxEvals(max.evals))
  }

  if (!is.null(target.fun.value)) {
    if (control$n.objectives > 1L)
      stop("Specifying target.fun.value is only useful in single crit optimization.")
    stop.conds = c(stop.conds, makeMBOTerminationTargetFunValue(target.fun.value))
  }

  # sanity check stopping conditions
  lapply(stop.conds, function(stop.on) {
    assertFunction(stop.on, args = "opt.state")
  })

  control$stop.conds = stop.conds

  # store stuff in control object since it is needed internally
  control$iters = coalesce(iters, control$iters, Inf)
  control$time.budget = coalesce(time.budget, control$time.budget, Inf)
  control$exec.time.budget = coalesce(exec.time.budget, control$exec.time.budget, Inf)
  control$max.evals = coalesce(max.evals, Inf)

  return(control)
}
