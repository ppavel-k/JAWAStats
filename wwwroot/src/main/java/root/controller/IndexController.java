package root.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.servlet.ModelAndView;
import root.service.ReportService;

import java.time.LocalDate;

@Controller
@RequiredArgsConstructor
public class IndexController {

    public static final String ROOT = "";

    private final ReportService reportService;

    @GetMapping(value = ROOT)
    public String index(Model model) {
        int currentYearValue = LocalDate.now().getYear();
        model.addAttribute("overview", reportService.getOverview(currentYearValue));
        model.addAttribute("monthlyView", reportService.getPerMonth(currentYearValue));
        return "index";
    }

    @GetMapping(value = "year/{year}")
    public String viewYear(@PathVariable Integer year, Model model) {
        model.addAttribute("overview", reportService.getOverview(year));
        model.addAttribute("monthlyView", reportService.getPerMonth(year));
        return "index";
    }

    @GetMapping(value = {"/index.html", "", "/index", "/index.htm"})
    public ModelAndView redirect(ModelMap model) {
        return new ModelAndView("redirect:" + ROOT, model);
    }

}
