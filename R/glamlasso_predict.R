#
#     Description of this R script:
#     R interface for glamlasso routines.
#
#     Intended for use with R.
#     Copyright (C) 2016 Adam Lund
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>
#

# @aliases glamlasso_predict glamlasso.predict
#' @title Make Prediction From a glamlasso Object
#'
#' @description  Given new covariate data this function computes the linear predictors 
#' based on the estimated model coefficients in an object produced by the function \code{glamlasso}. Note that the 
#' data can be supplied in two different formats: i) as a \eqn{n' \times p} matrix (\eqn{p} is the number of model 
#' coefficients and \eqn{n'} is the number of new data points) or ii) as a list of two or three matrices each of 
#' size \eqn{n_i' \times p_i, i = 1, 2, 3} (\eqn{n_i'} is the number of new marginal data points in the \eqn{i}th dimension).
#'
#'
#' @param object An object of Class glamlasso, produced with \code{glamlasso}.
#' @param x a matrix of size \eqn{n' \times p} with \eqn{n'} is the number of new data points.
#' @param X  A list containing the data matrices each of size \eqn{n'_{i} \times p_i},  
#' where \eqn{n'_{i}} is the number of new data points in  the \eqn{i}th dimension.
#' @param ... ignored
#' 
#' @return
#' A list of length \code{nlambda} containing the linear predictors for each  model. If 
#' new covariate data is supplied in one \eqn{n' \times p} matrix \code{x} each 
#' item  is a vector of length \eqn{n'}. If the data is supplied as a list of 
#' matrices each of size \eqn{n'_{i} \times p_i},  each item is an array of size \eqn{n'_1 \times \cdots \times n'_d}, with \eqn{d\in \{2,3\}}.
#'  
#' @examples  
#' n1 <- 65; n2 <- 26; n3 <- 13; p1 <- 13; p2 <- 5; p3 <- 4
#' X1 <- matrix(rnorm(n1 * p1), n1, p1) 
#' X2 <- matrix(rnorm(n2 * p2), n2, p2) 
#' X3 <- matrix(rnorm(n3 * p3), n3, p3) 
#' Beta <- array(rnorm(p1 * p2 * p3) * rbinom(p1 * p2 * p3, 1, 0.1), c(p1 , p2, p3))
#' mu <- RH(X3, RH(X2, RH(X1, Beta)))
#' Y <- array(rnorm(n1 * n2 * n3, mu), dim = c(n1, n2, n3))
#' fit <- glamlasso(list(X1, X2, X3), Y)
#' 
#' ##new data in matrix form
#' x <- matrix(rnorm(p1 * p2 * p3), nrow = 1)
#' predict(fit, x = x)[[100]]
#' 
#' ##new data in tensor component form
#' X1 <- matrix(rnorm(p1), nrow = 1)
#' X2 <- matrix(rnorm(p2), nrow = 1)
#' X3 <- matrix(rnorm(p3), nrow = 1)
#' predict(fit, X = list(X1, X2, X3))[[100]]
#' 
#' @author Adam Lund
#' @method predict glamlasso
#' @export

predict.glamlasso <- function(object, x = NULL, X = NULL, ...) {
  
nlambda <- length(object$lambda)
family <- object$family  
p <- object$dimcoef
res <- vector("list", nlambda)  
 
if(is.null(x) & is.null(X)){

stop(paste("no new data provided")) 

}else if(is.null(x) == FALSE & is.null(X)){
  
x <- as.matrix(x)
coldim <- dim(x)[2]
nofcoef <- prod(p)
  
if(coldim != nofcoef){
  
stop(
paste("column dimension of the new data x (", coldim ,") is not equal to the number of coefficients p (", nofcoef ,")", sep = "")
)

} 
  
for(i in 1:nlambda){

beta <- object$coef[ , i]
res[[i]] <- mu(x %*% beta, family)    
  
}

} else if(is.null(x)  & is.null(X) == FALSE) {
  dimglam <- length(X)
  
  if (dimglam < 2 || dimglam > 3){
    
    stop(paste("the dimension of the GLAM must be 2 or 3!"))
    
  }else if (dimglam == 2){X[[3]] <- matrix(1, 1, 1)} 
  
  X1 <- X[[1]]
  X2 <- X[[2]]
  X3 <- X[[3]]
  
  dimX <- rbind(dim(X1), dim(X2), dim(X3))
  
  n1 <- dimX[1, 1]
  n2 <- dimX[2, 1]
  n3 <- dimX[3, 1]
  p1 <- dimX[1, 2]
  p2 <- dimX[2, 2]
  p3 <- dimX[3, 2]
  n <- prod(dimX[,1])
  p <- prod(dimX[,2])


 
  
coldim <- dim(X1)[2] * dim(X2)[2] * dim(X3)[2]   
  
if(coldim != p){
    
stop(    
paste("column dimension of the kronecker product of the new data X (", coldim ,") is not equal to the number of coefficients p (", p ,")", sep = "")
)
    
} 
  
for(i in 1:nlambda){
    
beta <- array(object$coef[ , i], dim = c(p1, p2, p3))
res[[i]] <- mu(RH(X3, RH(X2, RH(X1, beta))), family)
    
}
   
}else{stop(paste("dimension of new data inconsistent with existing data"))}

class(res) <- "glamlasso"

return(res)

}
