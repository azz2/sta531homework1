library(BB)
library(truncnorm)
f <- function(y, theta){
  return((y-theta)/(1+(y-theta)^2))
}

g <- function(theta){
  y.vec <- c(-2,-1,0,1.5,2.5)
  return(sum(sapply(y.vec, function(y) {f(y,theta)})))
}

# pos.mod <- BBoptim(-1, g)$value
pos.mod <- uniroot(g, c(-1,1))$root
d2.log.f <- function(y, theta){
  return(((y-theta)^2-1)/((y-theta)^2+1)^2)
}

d2.log.g <- function(y.vec, theta){
  return(2*sum(sapply(y.vec, function(y) {d2.log.f(y,theta)})))
}

y.vec <- c(-2,-1,0,1.5,2.5)
g(pos.mod)
g(0)
g(1)
mle.mean <- g(0)
mle.var <- -1/d2.log.g(y.vec, 0)
mle.norm.approx <- dtruncnorm(theta.seq,
                              a = 0,
                              b = 1,
                              mean = mle.mean,
                              sd = sqrt(mle.var))
nor.var <- -1/d2.log.g(y.vec, pos.mod)
# dist is N(pos.mod, nor.var)

# plot actual density
seq.length = 10000
theta.seq <- seq(from = 0,
                 to = 1,
                 length.out = seq.length)
pdf(file = "mapplot.pdf")
plot(theta.seq, 
     sapply(theta.seq, g),
     type = "l",
     xlab = expression(theta),
     ylab = "Score function")
dev.off()
cauchy.f <- function(y, theta){
  return((1+(y-theta)^2)^(-1))
}
unnorm.post <- function(y.vec, theta){
  return(prod(sapply(y.vec, function(y) {cauchy.f(y, theta)})))
}

unnorm.den <- sapply(theta.seq, function(theta) {unnorm.post(y.vec, theta)})
plot(theta.seq, unnorm.den)
post.tot <- sum(unnorm.den/seq.length)
norm.const <- 1/post.tot
norm.post <- function(y.vec, theta){
  norm.const*unnorm.post(y.vec, theta)
}
norm.den <- sapply(theta.seq, function(theta) {norm.post(y.vec, theta)})
trun.norm.den <- dtruncnorm(theta.seq, 
                            a = 0,
                            b = 1,
                            mean = pos.mod, 
                            sd = sqrt(nor.var))
pdf(file = "normapprox.pdf")
matplot(theta.seq, 
        cbind(norm.den,trun.norm.den), 
        type = "l",
        main = "MLE normal approximation",
        xlab = expression(theta),
        ylab = expression(density))
legend("topright", c("Density", "Normal Approx."),
       lty = c(1,2),
       col = c("black", "red"))
dev.off()

pdf(file = "mapapprox.pdf")
matplot(theta.seq,
        cbind(norm.den, mle.norm.approx),
        type = "l",
        main = "MAP normal approximation",
        xlab = expression(theta),
        ylab = "denisty")
legend("topright", c("Density", "Normal Approx."),
       lty = c(1,2),
       col = c("black", "red"))
dev.off()
# Problem 4 code#
library(MCMCpack)
ns <- c(1,10, 10^2, 10^3, 10^4, 10^5, 10^6, 10^7)
list.of.draws <- lapply(ns, function(x) {rexp(x, rate = 1)})
post.a <- 1+ns
post.b <- 1+sapply(list.of.draws, sum)
post.params <- cbind(post.a, post.b)
support.seq <- seq(from = 0,
                   to = 2,
                   length.out = 1000)
mat.of.den <- apply(post.params, 1, function(x)
  {dgamma(support.seq, shape = x[1], rate = x[2])})
matplot(support.seq, mat.of.den, type = "l")
# Y = X^2
psi.den <- function(x, shape, rate){
  return((1/2)*x^(-3/2)*dgamma(sqrt(x), shape = shape, rate = rate))
}
mat.of.sqr.den <- apply(post.params, 1, function(x)
  {psi.den(support.seq, shape = x[1], rate = x[2])})
matplot(support.seq, mat.of.sqr.den[,-1], type = "l")

mean.val <- function(theta){
  return((1/2)*(theta+1))
}
thetas <- apply(post.params, 1, function(x)
  {rgamma(1000, shape = x[1], rate = x[2])})

mean.val.theta <- apply(thetas, 1:2, mean.val)
means <- apply(thetas, 2, mean)
pdf(file = "meanval.pdf")
plot(log(ns), 
     means,
     type = "l",
     xlab = expression(log(n)),
     ylab = expression(bar(theta)[0]))
abline(h = 1, col = "red")
dev.off()
# Problem 9 code#

# MLE function
MLE <- function(y){
  if ((y <= 1) && (y >= 0)){
    return(y)
  } else if (y < 0){
    return(0)
  } else {
    return(1)
  }
}

postMean <- function(y, variance){
  sd <- sqrt(variance)
  post.mean <- y + sd*(dnorm(-y/sd)-dnorm((1-y)/sd))/(pnorm((1-y)/sd)-pnorm(-y/sd))
  return(post.mean)
}

true.theta <- runif(1)
trails <- 10000
variance <- seq(from = .1, to = 5, length.out = 100)
computeMSE <- function(true.theta, 
                       trails, 
                       variance,
                       to.return = "MSE"){
  thetas <- rnorm(trails,
                  mean = true.theta,
                  sd = sqrt(variance))
  MLE.res <- sapply(thetas, MLE)
  post.mean.res <- sapply(thetas, function(x)
    {postMean(x, variance)})
  MLE.mean <- mean(MLE.res)
  post.mean.mean <- mean(post.mean.res)
  MLE.var <- var(MLE.res)
  post.mean.var <- var(post.mean.res)
  MLE.MSE <- (MLE.mean - true.theta)^2+MLE.var
  post.mean.MSE <- ((post.mean.mean - true.theta)^2+
                      post.mean.var)
  MLE.vals <- list("results" = MLE.res,
                   "mean" = MLE.mean,
                   "variance" = MLE.var,
                   "MSE" = MLE.MSE)
  post.mean.vals <- list("results" = post.mean.res, 
                         "mean" = post.mean.mean,
                         "variance" = post.mean.var, 
                         "MSE" = post.mean.MSE)
  return(c(MLE.vals[[to.return]], 
           post.mean.vals[[to.return]]))
}
makeLists <- function(true.theta,
                      trails,
                      variance, 
                      to.return){
  list.of.vals <- lapply(variance, function(x){
    computeMSE(true.theta, trails, x, to.return)
  })
  MLE.vals <- sapply(list.of.vals, "[[", 1)
  post.mean.vals <- sapply(list.of.vals, "[[", 2)
  matplot(variance, 
          cbind(MLE.vals, post.mean.vals),
          type = "l",
          lty = c(1,2),
          main = paste0(to.return, "; True mean: ", true.theta),
          ylab = to.return)
  legend("topleft",
         c("MLE", "Post. Mean"),
         lty = c(1,2),
         col = c("black", "red"))
}
pdf(file = "mse5.pdf")
makeLists(.5, trails, variance, "MSE")
dev.off()
pdf(file = "mse1.pdf")
makeLists(1, trails, variance, "MSE")
dev.off()
pdf(file = "mse0.pdf")
makeLists(0, trails, variance, "MSE")
dev.off()
makeLists(true.theta, trails, variance, "variance")

# Problem 15
c <- qnorm(.75)
val1 <- (5/4)*(1+sqrt(5)*c/2)
val2 <- (5/4)*(1-sqrt(5)*c/2)
p1 <- 1-pnorm(val1, mean = 1, sd = 1)
p2 <- pnorm(val2, mean = 1, sd = 1)
prob <- p1+p2

computeCoverage <- function(cover, true.theta){
  c <- qnorm((1+cover)/2)
  val1 <- (5/4)*(true.theta + sqrt(5)*c/2)
  val2 <- (5/4)*(true.theta - sqrt(5)*c/2)
  p1 <- 1-pnorm(val1, mean = true.theta, sd = 1)
  p2 <- pnorm(val2, mean = true.theta, sd = 1)
  prob <- 1-(p1+p2)
  return(prob)
}
theta.seq <- seq(from = -16, to = 16, length.out = 10000)
coverage <- sapply(theta.seq, function(x) {
  computeCoverage(.5, x)})
hist(coverage)
computeCoverage(.5, 2)

computeFreq <- function(cover, true.theta){
  c <- qnorm((1+cover)/2)
  val1 <- true.theta+c
  val2 <- true.theta-c
  p1 <- 1- pnorm(val1, mean = true.theta, sd = 1)
  p2 <- pnorm(val2, mean = true.theta, sd = 1)
  prob <- p1+p2
  return(prob)
}
freq.cover <- sapply(theta.seq, function(x) {
  computeFreq(.5, x)
})
lines(theta.seq, freq.cover)

pdf(file = "coverage.pdf")
matplot(theta.seq, 
        cbind(coverage, freq.cover), 
        type = "l",
        main = "Bayesian and Frequentist Coverage",
        xlab = "True mean",
        ylab = "Coverage")
dev.off()
