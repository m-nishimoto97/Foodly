// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import ProfileMenuController from "controllers/profile_menu_controller"
import FdCarouselController  from "controllers/fd_carousel_controller"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
application.register("profile-menu", ProfileMenuController)
application.register("fd-carousel",  FdCarouselController)

