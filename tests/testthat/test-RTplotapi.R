root_path <- "http://localhost"
api_port <- httpuv::randomPort()
api <- callr::r_bg(
  function(port) {
    devtools::load_all()
    plumber::plumb(file='../../R/RTplotapi.R')$run(port = port)
  }, args = list(port = api_port)
)
Sys.sleep(3) # wait 3 seconds for plumber api to spin up

withr::defer({api$kill()})

test_that("API is alive", {
  expect_true(api$is_alive())
})

test_that("example data works", {
  test <- function(er, pe=NULL) {
    r <- httr::POST(url = root_path, port = api_port, path = "plot", query = list(exposure_route = er, predicted_exposure = pe))
    expect_equal(r$status_code, 200)
    expect_equal(r$headers$`content-type`, "image/png")
  }
  test("oral", 0.5)
  test("inhalation", 0.5)
  test("oral")
  test("inhalation")
})

test_that("request body data works", {
  test <- function(er, pe=NULL, t=NULL) {
    r <- httr::POST(url = root_path, port = api_port, path = "plot", body = jsonlite::toJSON(RTplot::example_11_1), query = list(exposure_route = er, predicted_exposure = pe, title = t))
    expect_equal(r$status_code, 200)
    expect_equal(r$headers$`content-type`, "image/png")
    if (!is.null(t)) expect_true(grepl(paste0("This chart has title '", t), r$headers$descriptive_text, fixed = TRUE))
  }
  test("oral", 0.5)
  test("inhalation", 0.5)
  test("oral")
  test("inhalation")
  #test("oral", t = "New Title") #title customization currently disabled
})

test_that("invalid parameters returns error", {
  test <- function(er, pe=NULL, t=NULL, expected_error_message) {
    r <- httr::POST(url = root_path, port = api_port, path = "plot", body = jsonlite::toJSON(RTplot::example_11_1), query = list(exposure_route = er, predicted_exposure = pe, title = t))
    expect_equal(r$status_code, 400)
    expect_equal(jsonlite::fromJSON(rawToChar(r$content))$error, expected_error_message)
  }
  test("none", expected_error_message = "Exposure Route must be either 'oral' or 'inhalation'.")
  test("oral", pe = ".18i", expected_error_message = "Predicted exposure must be a number.")
  # following are do not seem possible to test, numbers get interpreted as strings in query parameters
  # test(1, expected_error_message = "Exposure Route must be of type string.")
  # test("oral", t = 1, expected_error_message = "Title must be of type string.")
})


test_that("bug regression data data works: https://github.com/USEPA/RTplot/issues/28", {
  test <- function(er, pe=NULL) {
    r <- httr::POST(url = root_path, port = api_port, path = "plot",body = jsonlite::toJSON(bug_12_12), query = list(exposure_route = er, predicted_exposure = pe))
    expect_equal(r$status_code, 200)
    expect_equal(r$headers$`content-type`, "image/png")
  }
  test("inhalation", 0.5)
})
