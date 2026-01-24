package root.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.ui.ModelMap;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.servlet.ModelAndView;

@Controller
@RequiredArgsConstructor
public class IndexController {

    public static final String ROOT = "a";

    @GetMapping(value = ROOT)
    public String index(Model model) {
        // model.addAttribute("baseLayout", baseLayout);

        model.addAttribute("aaa");
        return "root";
    }

    @GetMapping(value = {"/index.html", "", "/index", "/index.htm"})
    public ModelAndView redirect(ModelMap model) {
        return new ModelAndView("redirect:" + ROOT, model);
    }

}
