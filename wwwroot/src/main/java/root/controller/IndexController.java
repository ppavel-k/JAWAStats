package root.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.servlet.ModelAndView;
import root.service.ReportService;

@Controller
@RequiredArgsConstructor
public class IndexController {

    public static final String ROOT = "";

    private final ReportService reportService;

    private final ReportService reportService;

    @GetMapping(value = ROOT)
    public String index(Model model) {
        model.addAttribute("overview", reportService.getOverview());

//         model.addAttribute("aaa");
        return "root";
    }

    @GetMapping(value = {"/index.html", "", "/index", "/index.htm"})
    public ModelAndView redirect(ModelMap model) {
        return new ModelAndView("redirect:" + ROOT, model);
    }

}
