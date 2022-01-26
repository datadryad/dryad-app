import React, { Component, Fragment } from "react";
import PropTypes from "prop-types";

class RorAutocomplete extends Component {
  static propTypes = {
    options: PropTypes.instanceOf(Array)
  };

  static defaultProps = {
    options: []
  };

  constructor(props) {
    super(props);

    this.state = {
      activeOption: 0,
      filteredOptions: [],
      showOptions: false,
      userInput: ""
    };
  }

  onChange = (e) => {
    const { options } = this.props;
    const userInput = e.currentTarget.value;

    const filteredOptions = options.filter(
        (option) => option.toLowerCase().indexOf(userInput.toLowerCase()) > -1
    );

    this.setState({
      activeOption: 0,
      filteredOptions,
      showOptions: true,
      userInput: e.currentTarget.value
    });
  };

  onClick = (e) => {
    this.setState({
      activeOption: 0,
      filteredOptions: [],
      showOptions: false,
      userInput: e.currentTarget.innerText
    });
  };

  onKeyDown = (e) => {
    const { activeOption, filteredOptions } = this.state;

    if (e.keyCode === 13) {
      this.setState({
        activeOption: 0,
        showOptions: false,
        userInput: filteredOptions[activeOption]
      });
    } else if (e.keyCode === 38) {
      if (activeOption === 0) {
        return;
      }

      this.setState({ activeOption: activeOption - 1 });
    } else if (e.keyCode === 40) {
      if (activeOption - 1 === filteredOptions.length) {
        return;
      }

      this.setState({ activeOption: activeOption + 1 });
    }
  };

  render() {
    const {
      onChange,
      onClick,
      onKeyDown,
      state: { activeOption, filteredOptions, showOptions, userInput }
    } = this;

    let optionsListComponent;

    if (showOptions && userInput) {
      if (filteredOptions.length) {
        optionsListComponent = (
            <ul class="options">
              {filteredOptions.map((option, index) => {
                let className;

                if (index === activeOption) {
                  className = "option-active";
                }

                return (
                    <li className={className} key={option} onClick={onClick}>
                      {option}
                    </li>
                );
              })}
            </ul>
        );
      } else {
        optionsListComponent = (
            <div class="no-options">
              <em>No options!</em>
            </div>
        );
      }
    }

    return (
        <Fragment>
          <input
              type="text"
              onChange={onChange}
              onKeyDown={onKeyDown}
              value={userInput}
          />
          {optionsListComponent}
        </Fragment>
    );
  }
}

export default RorAutocomplete;